#!/bin/bash

# =========================================================
# Apache Tomcat Enterprise Installation Script - Ubuntu
# =========================================================
# Features
# - Configure Hostname
# - Install Utility Packages
# - Install Java 17
# - Configure JAVA_HOME Permanently
# - Install Apache Tomcat Latest
# - Create Tomcat User
# - Configure Admin User & Roles
# - Enable Global Access
# - Configure systemd Service
# - Open Firewall Port
# - Validate Service / Ports / Process
# =========================================================

set -e

# =========================================================
# VARIABLES
# =========================================================

HOSTNAME_FQDN="tomcat.cloudbinary.in"

TOMCAT_VERSION="10.1.55"
TOMCAT_PACKAGE="apache-tomcat-${TOMCAT_VERSION}"
TOMCAT_TAR="${TOMCAT_PACKAGE}.tar.gz"

TOMCAT_DIR="/opt/tomcat"
TOMCAT_USER="tomcat"

JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64/"

ADMIN_USER="admin"
ADMIN_PASSWORD="redhat@123"

# =========================================================
# CONFIGURE HOSTNAME
# =========================================================

echo "=================================================="
echo " Configuring Hostname"
echo "=================================================="

sudo hostnamectl set-hostname "${HOSTNAME_FQDN}"

CURRENT_IP=$(hostname -I | awk '{ print $1 }')

if ! grep -q "${HOSTNAME_FQDN}" /etc/hosts; then
    echo "${CURRENT_IP} ${HOSTNAME_FQDN}" | sudo tee -a /etc/hosts
fi

echo ""
echo "Hostname Details:"
hostnamectl

# =========================================================
# UPDATE REPOSITORIES
# =========================================================

echo "=================================================="
echo " Updating Ubuntu Repositories"
echo "=================================================="

sudo apt-get update -y

# =========================================================
# INSTALL UTILITIES
# =========================================================

echo "=================================================="
echo " Installing Utility Packages"
echo "=================================================="

sudo apt-get install -y \
git \
wget \
unzip \
curl \
tree \
net-tools \
ufw

# =========================================================
# INSTALL JAVA 17
# =========================================================

echo "=================================================="
echo " Installing Java 17"
echo "=================================================="

sudo apt-get install openjdk-17-jdk -y

java -version

# =========================================================
# CONFIGURE JAVA ENVIRONMENT VARIABLES
# =========================================================

echo "=================================================="
echo " Configuring JAVA_HOME"
echo "=================================================="

# Backup existing environment file
sudo cp -pvr /etc/environment "/etc/environment_$(date +%F_%R)"

# Add JAVA_HOME only if not present
if ! grep -q "JAVA_HOME" /etc/environment; then
    echo "JAVA_HOME=${JAVA_HOME_PATH}" | sudo tee -a /etc/environment
fi

# Add JRE_HOME only if not present
if ! grep -q "JRE_HOME" /etc/environment; then
    echo "JRE_HOME=${JAVA_HOME_PATH}" | sudo tee -a /etc/environment
fi

# Export for current shell
export JAVA_HOME=${JAVA_HOME_PATH}
export JRE_HOME=${JAVA_HOME_PATH}
export PATH=$PATH:$JAVA_HOME/bin

echo "JAVA_HOME=${JAVA_HOME}"

# =========================================================
# CREATE TOMCAT USER
# =========================================================

echo "=================================================="
echo " Creating Tomcat User"
echo "=================================================="

if id "${TOMCAT_USER}" &>/dev/null; then
    echo "Tomcat user already exists"
else
    sudo useradd -r -m -U -d ${TOMCAT_DIR} -s /bin/false ${TOMCAT_USER}
fi

# =========================================================
# DOWNLOAD TOMCAT
# =========================================================

echo "=================================================="
echo " Downloading Apache Tomcat ${TOMCAT_VERSION}"
echo "=================================================="

cd /opt/

sudo wget \
https://downloads.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/${TOMCAT_TAR}

# =========================================================
# EXTRACT TOMCAT
# =========================================================

echo "=================================================="
echo " Extracting Apache Tomcat"
echo "=================================================="

sudo tar xvzf ${TOMCAT_TAR}

# =========================================================
# BACKUP OLD TOMCAT
# =========================================================

if [ -d "${TOMCAT_DIR}" ]; then
    sudo mv ${TOMCAT_DIR} \
    ${TOMCAT_DIR}_backup_$(date +%F_%R)
fi

# =========================================================
# RENAME TOMCAT DIRECTORY
# =========================================================

sudo mv ${TOMCAT_PACKAGE} tomcat

# =========================================================
# SET OWNERSHIP & PERMISSIONS
# =========================================================

echo "=================================================="
echo " Setting Permissions"
echo "=================================================="

sudo chown -R ${TOMCAT_USER}:${TOMCAT_USER} ${TOMCAT_DIR}
sudo chmod -R 755 ${TOMCAT_DIR}

# =========================================================
# BACKUP TOMCAT USERS FILE
# =========================================================

echo "=================================================="
echo " Configuring Tomcat Users"
echo "=================================================="

sudo cp -pvr \
${TOMCAT_DIR}/conf/tomcat-users.xml \
"${TOMCAT_DIR}/conf/tomcat-users.xml_$(date +%F_%R)"

# =========================================================
# CONFIGURE TOMCAT USERS
# =========================================================

sudo tee ${TOMCAT_DIR}/conf/tomcat-users.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">

<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>

<user username="${ADMIN_USER}"
      password="${ADMIN_PASSWORD}"
      roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>

</tomcat-users>
EOF

# =========================================================
# ENABLE GLOBAL ACCESS
# =========================================================

echo "=================================================="
echo " Enabling Global Access"
echo "=================================================="

sudo tee ${TOMCAT_DIR}/webapps/manager/META-INF/context.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<Context antiResourceLocking="false" privileged="true">
</Context>
EOF

sudo tee ${TOMCAT_DIR}/webapps/host-manager/META-INF/context.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<Context antiResourceLocking="false" privileged="true">
</Context>
EOF

# =========================================================
# ENABLE LISTEN ON ALL INTERFACES
# =========================================================

echo "=================================================="
echo " Configuring Port Binding"
echo "=================================================="

sudo sed -i 's/port="8080"/address="0.0.0.0" port="8080"/' \
${TOMCAT_DIR}/conf/server.xml

# =========================================================
# CREATE SYSTEMD SERVICE
# =========================================================

echo "=================================================="
echo " Creating Tomcat systemd Service"
echo "=================================================="

sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=${JAVA_HOME_PATH}
Environment=JRE_HOME=${JAVA_HOME_PATH}
Environment=CATALINA_PID=${TOMCAT_DIR}/temp/tomcat.pid
Environment=CATALINA_HOME=${TOMCAT_DIR}
Environment=CATALINA_BASE=${TOMCAT_DIR}
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=${TOMCAT_DIR}/bin/startup.sh
ExecStop=${TOMCAT_DIR}/bin/shutdown.sh

User=${TOMCAT_USER}
Group=${TOMCAT_USER}

UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# =========================================================
# RELOAD SYSTEMD
# =========================================================

sudo systemctl daemon-reload

# =========================================================
# ENABLE & START TOMCAT
# =========================================================

echo "=================================================="
echo " Starting Tomcat Service"
echo "=================================================="

sudo systemctl enable tomcat
sudo systemctl restart tomcat

# =========================================================
# OPEN FIREWALL PORT
# =========================================================

echo "=================================================="
echo " Opening Firewall Port 8080"
echo "=================================================="

sudo ufw allow 8080/tcp || true

# =========================================================
# VALIDATION
# =========================================================

echo "=================================================="
echo " Service Status"
echo "=================================================="

sudo systemctl status tomcat --no-pager

echo ""
echo "=================================================="
echo " Process Verification"
echo "=================================================="

ps -aux | grep tomcat || true

echo ""
echo "=================================================="
echo " Port Verification"
echo "=================================================="

netstat -ltcdp | grep 8080 || true

# =========================================================
# SUCCESS MESSAGE
# =========================================================

echo ""
echo "=================================================="
echo " Apache Tomcat Installation Completed"
echo "=================================================="
echo ""
echo "Hostname        : ${HOSTNAME_FQDN}"
echo "JAVA_HOME       : ${JAVA_HOME_PATH}"
echo ""
echo "Tomcat URL:"
echo "http://${CURRENT_IP}:8080"
echo ""
echo "Manager URL:"
echo "http://${CURRENT_IP}:8080/manager/html"
echo ""
echo "Host Manager URL:"
echo "http://${CURRENT_IP}:8080/host-manager/html"
echo ""
echo "Admin Username  : ${ADMIN_USER}"
echo "Admin Password  : ${ADMIN_PASSWORD}"
echo ""
echo "Useful Commands:"
echo "systemctl status tomcat"
echo "systemctl restart tomcat"
echo "systemctl stop tomcat"
echo "journalctl -u tomcat -f"
echo ""
echo "=================================================="