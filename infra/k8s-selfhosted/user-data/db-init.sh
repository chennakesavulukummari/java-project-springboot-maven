#!/bin/bash
# Database Node Initialization Script
# Ubuntu 22.04 LTS - MySQL 8.0 Server

set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables from Terraform
CLUSTER_NAME="${cluster_name}"
DB_DATA_DEVICE="/dev/nvme1n1"  # Second EBS volume
DB_MOUNT_POINT="/data"
DB_ROOT_PASSWORD="$(openssl rand -base64 32)"
MYSQL_VERSION="8.0"

echo -e "${YELLOW}=== Starting Database Node Setup ===${NC}"

# ============================================================================
# System Updates
# ============================================================================

echo -e "${YELLOW}[1/6] Updating system packages...${NC}"
apt-get update
apt-get upgrade -y
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    net-tools \
    jq \
    ntp \
    chrony \
    parted \
    lvm2 \
    xfsprogs \
    sudo

# ============================================================================
# Format and Mount EBS Volume
# ============================================================================

echo -e "${YELLOW}[2/6] Formatting and mounting database volume...${NC}"

# Wait for volume to appear
ELAPSED=0
while [ ! -e "$DB_DATA_DEVICE" ] && [ $ELAPSED -lt 60 ]; do
    echo "Waiting for volume $DB_DATA_DEVICE..."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ ! -e "$DB_DATA_DEVICE" ]; then
    echo -e "${RED}ERROR: Volume not found${NC}"
    exit 1
fi

# Create XFS filesystem
mkfs.xfs -f "$DB_DATA_DEVICE" || true

# Create mount point
mkdir -p "$DB_MOUNT_POINT"

# Get UUID
VOLUME_UUID=$(blkid -s UUID -o value "$DB_DATA_DEVICE")

# Add to fstab
echo "UUID=$VOLUME_UUID $DB_MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab

# Mount volume
mount "$DB_DATA_DEVICE" "$DB_MOUNT_POINT"
chmod 755 "$DB_MOUNT_POINT"

echo -e "${GREEN}Volume mounted at $DB_MOUNT_POINT${NC}"

# ============================================================================
# Install MySQL Server
# ============================================================================

echo -e "${YELLOW}[3/6] Installing MySQL ${MYSQL_VERSION}...${NC}"

# Add MySQL repository
curl -fsSL https://dev.mysql.com/doc/apt-mysqlrepo-intro/index.html | grep -A 1 "ubuntu-focal" | head -1
curl https://dev.mysql.com/get/mysql-apt-config_0.8.20-1_all.deb --output mysql-apt-config.deb
dpkg -i mysql-apt-config.deb
rm mysql-apt-config.deb

# Install MySQL Server
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mysql-server \
    mysql-client \
    mysqldump

# Enable and start MySQL
systemctl enable mysql
systemctl start mysql

echo -e "${GREEN}MySQL Server installed and running${NC}"

# ============================================================================
# Configure MySQL
# ============================================================================

echo -e "${YELLOW}[4/6] Configuring MySQL...${NC}"

# Move MySQL data directory to mounted volume
systemctl stop mysql

# Copy existing data
mkdir -p "$DB_MOUNT_POINT/mysql"
rsync -av /var/lib/mysql/ "$DB_MOUNT_POINT/mysql/"
chown -R mysql:mysql "$DB_MOUNT_POINT/mysql"
chmod 700 "$DB_MOUNT_POINT/mysql"

# Update MySQL configuration
cat > /etc/mysql/conf.d/99-custom.cnf << EOF
[mysqld]
datadir=$DB_MOUNT_POINT/mysql
socket=$DB_MOUNT_POINT/mysql/mysql.sock
log-error=$DB_MOUNT_POINT/mysql/error.log
pid-file=$DB_MOUNT_POINT/mysql/mysql.pid

# Performance tuning
max_connections=1000
innodb_buffer_pool_size=2G
innodb_log_file_size=512M
slow-query-log=1
slow-query-log-file=$DB_MOUNT_POINT/mysql/slow.log
long_query_time=2

# Binary logging for replication
server-id=1
log_bin=$DB_MOUNT_POINT/mysql/binlog
binlog_format=ROW
EOF

# Update MySQL Socket location
sed -i 's|/var/run/mysqld/mysqld.sock|'$DB_MOUNT_POINT'/mysql/mysql.sock|g' /etc/mysql/my.cnf

# Start MySQL again
mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld
systemctl start mysql

# ============================================================================
# Secure MySQL Installation
# ============================================================================

echo -e "${YELLOW}[5/6] Securing MySQL installation...${NC}"

# Set root password
mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';"

# Remove anonymous users
mysql -uroot -p"$DB_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='';"

# Disable remote root login
mysql -uroot -p"$DB_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

# Remove test database
mysql -uroot -p"$DB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;"

# Create application database user
APP_DB_PASSWORD="$(openssl rand -base64 32)"
mysql -uroot -p"$DB_ROOT_PASSWORD" -e "CREATE USER 'appuser'@'%' IDENTIFIED BY '$APP_DB_PASSWORD';"
mysql -uroot -p"$DB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'%';"
mysql -uroot -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# ============================================================================
# Create Application Database
# ============================================================================

echo -e "${YELLOW}[6/6] Creating application database...${NC}"

mysql -uroot -p"$DB_ROOT_PASSWORD" << 'MYSQL_EOF'
CREATE DATABASE IF NOT EXISTS application_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE application_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user (user_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create order items table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    INDEX idx_order (order_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

MYSQL_EOF

# ============================================================================
# Enable Replication Support
# ============================================================================

echo -e "${YELLOW}Setting up replication support...${NC}"

mysql -uroot -p"$DB_ROOT_PASSWORD" << 'MYSQL_EOF'
CREATE USER 'repl'@'%' IDENTIFIED BY 'repl_password_123';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
MYSQL_EOF

# ============================================================================
# Save Credentials
# ============================================================================

echo -e "${YELLOW}Saving database credentials...${NC}"

cat > /var/lib/cloud/db-credentials.txt << EOF
=== MySQL Database Credentials ===
Root Password: $DB_ROOT_PASSWORD
App User: appuser
App Password: $APP_DB_PASSWORD
Replication User: repl
Replication Password: repl_password_123

Database: application_db
Host: $(hostname -I | awk '{print $1}')
Port: 3306
Data Directory: $DB_MOUNT_POINT/mysql

!!! IMPORTANT: Save these credentials in a secure location !!!
EOF

chmod 600 /var/lib/cloud/db-credentials.txt

# ============================================================================
# Install Backup Tools
# ============================================================================

echo -e "${YELLOW}Installing backup tools...${NC}"

apt-get install -y percona-xtrabackup-80 || apt-get install -y mariadb-backup

# Create backup directory
mkdir -p "$DB_MOUNT_POINT/backups"
chown -R mysql:mysql "$DB_MOUNT_POINT/backups"
chmod 700 "$DB_MOUNT_POINT/backups"

# Create backup script
cat > /usr/local/bin/backup-mysql.sh << 'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="'$DB_MOUNT_POINT'/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql.gz"

echo "Starting MySQL backup to $BACKUP_FILE..."
mysqldump -uroot -p"$DB_ROOT_PASSWORD" --all-databases --single-transaction --quick --lock-tables=false | gzip > "$BACKUP_FILE"
echo "Backup completed: $BACKUP_FILE"

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +7 -delete
BACKUP_SCRIPT

chmod +x /usr/local/bin/backup-mysql.sh

# ============================================================================
# Setup Daily Backup Cron
# ============================================================================

echo "0 2 * * * /usr/local/bin/backup-mysql.sh" | crontab -

# ============================================================================
# Installation Complete
# ============================================================================

echo -e "${GREEN}=== Database Node Setup Complete ===${NC}"
echo ""
echo -e "${YELLOW}Database Information:${NC}"
echo "Host: $(hostname)"
echo "IP: $(hostname -I | awk '{print $1}')"
echo "MySQL Version: $MYSQL_VERSION"
echo "Data Directory: $DB_MOUNT_POINT/mysql"
echo "Database: application_db"
echo ""
echo -e "${YELLOW}Default Credentials Saved to:${NC}"
echo "/var/lib/cloud/db-credentials.txt"
echo ""
echo -e "${YELLOW}Backup Location:${NC}"
echo "$DB_MOUNT_POINT/backups"
echo ""
echo -e "${YELLOW}MySQL Status:${NC}"
systemctl status mysql --no-pager || true
mysql -uroot -p"$DB_ROOT_PASSWORD" -e "SHOW DATABASES;" || true
