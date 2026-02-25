#!/bin/bash
set -e

############################
# VARIABLES
############################
MYSQL_ROOT_PASSWORD="Root@123"
MYSQL_APP_DATABASE="springboot_db"
MYSQL_APP_USER="appuser"
MYSQL_APP_PASSWORD="AppUser@123"
MYSQL_APP_HOST="%"
MYSQL_PORT=3306

############################
# UPDATE & INSTALL PACKAGES
############################
apt update -y
apt install -y wget curl vim gnupg lsb-release

############################
# ADD MYSQL APT REPOSITORY
############################
cd /tmp
wget https://dev.mysql.com/get/mysql-apt-config_0.8.30-1_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.30-1_all.deb
apt update -y

############################
# INSTALL MYSQL SERVER
############################
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server mysql-client

############################
# CONFIGURE MYSQL
############################
cat <<EOF > /etc/mysql/mysql.conf.d/custom.cnf
[mysqld]
# Network
port                    = ${MYSQL_PORT}
bind-address            = 0.0.0.0

# Character Set
character-set-server    = utf8mb4
collation-server        = utf8mb4_unicode_ci

# Connection
max_connections         = 150
wait_timeout            = 28800
interactive_timeout     = 28800

# InnoDB
innodb_buffer_pool_size = 256M
innodb_log_file_size    = 64M
innodb_flush_log_at_trx_commit = 1
innodb_file_per_table   = 1

# Logging
slow_query_log          = 1
slow_query_log_file     = /var/log/mysql/mysql-slow.log
long_query_time         = 2

# Security
local_infile            = 0

[client]
default-character-set   = utf8mb4
EOF

############################
# ENABLE & START MYSQL
############################
systemctl daemon-reload
systemctl enable mysql
systemctl restart mysql

############################
# WAIT FOR MYSQL TO BE READY
############################
echo "Waiting for MySQL to be ready..."
for i in {1..30}; do
    if mysqladmin ping -u root --silent 2>/dev/null; then
        echo "MySQL is ready!"
        break
    fi
    echo "Attempt $i: MySQL not ready yet, waiting..."
    sleep 2
done

############################
# SECURE MYSQL INSTALLATION
############################
mysql -u root <<EOSQL
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Flush privileges
FLUSH PRIVILEGES;
EOSQL

############################
# CREATE APPLICATION DATABASE & USER
############################
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOSQL
-- Create application database
CREATE DATABASE IF NOT EXISTS ${MYSQL_APP_DATABASE}
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Create application user with full access to app database
CREATE USER IF NOT EXISTS '${MYSQL_APP_USER}'@'${MYSQL_APP_HOST}'
  IDENTIFIED BY '${MYSQL_APP_PASSWORD}';

GRANT ALL PRIVILEGES ON ${MYSQL_APP_DATABASE}.* TO '${MYSQL_APP_USER}'@'${MYSQL_APP_HOST}';

FLUSH PRIVILEGES;
EOSQL

############################
# CONFIGURE FIREWALL
############################
ufw allow ${MYSQL_PORT}/tcp || true

############################
# VERIFY MYSQL IS RUNNING
############################
systemctl status mysql --no-pager

############################
# DISPLAY ACCESS INFO
############################
echo "----------------------------------------"
echo "MySQL Server Installed Successfully"
echo "Host: $(hostname -I | awk '{print $1}')"
echo "Port: ${MYSQL_PORT}"
echo "Root Password: ${MYSQL_ROOT_PASSWORD}"
echo "App Database: ${MYSQL_APP_DATABASE}"
echo "App User: ${MYSQL_APP_USER}"
echo "App Password: ${MYSQL_APP_PASSWORD}"
echo "App Host Access: ${MYSQL_APP_HOST}"
echo "----------------------------------------"

############################
# CLEANUP
############################
rm -f /tmp/mysql-apt-config_0.8.30-1_all.deb
