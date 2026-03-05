#!/bin/bash
set -e

############################
# VARIABLES
############################
TOMCAT_VERSION="9.0.115"
TOMCAT_MAJOR_VERSION="9"
INSTALL_DIR="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

# Setup Hostname
sudo hostnamectl set-hostname "tomcat.madeofmemories.com"

# Update the hostname part of Host File
echo "`hostname -I | awk '{ print $1 }'` `hostname`" >> /etc/hosts

############################
# UPDATE & INSTALL PACKAGES
############################
apt update -y
apt install -y openjdk-21-jdk curl wget vim git tree

############################
# VERIFY JAVA
############################
java -version

############################
# CREATE ENVIRONMENT VARIABLES
############################

# Backup the Environment File
sudo cp -pvr /etc/environment "/etc/environment_$(date +%F_%R)"

# Create Environment Variables
echo "JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64/" >> /etc/environment

# Synchronize the Environment Variables
source /etc/environment

############################
# CREATE TOMCAT USER
############################
groupadd -r ${TOMCAT_GROUP} || true
useradd -r -g ${TOMCAT_GROUP} -d ${INSTALL_DIR} -s /bin/false ${TOMCAT_USER} || true

############################
# DOWNLOAD & INSTALL TOMCAT
############################
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Extract to /opt
tar -xvzf apache-tomcat-${TOMCAT_VERSION}.tar.gz
mv apache-tomcat-${TOMCAT_VERSION} ${INSTALL_DIR}

############################
# SET PERMISSIONS
############################
chown -R ${TOMCAT_USER}:${TOMCAT_GROUP} ${INSTALL_DIR}
chmod +x ${INSTALL_DIR}/bin/*.sh

############################
# CONFIGURE TOMCAT USERS
############################
cat <<EOF > ${INSTALL_DIR}/conf/tomcat-users.xml
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
  <user username="admin" password="redhat@123" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>

</tomcat-users>
EOF

############################
# ALLOW REMOTE ACCESS TO MANAGER APP
############################
# Update Manager App context.xml
# sed -i 's/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"/g' ${INSTALL_DIR}/webapps/manager/META-INF/context.xml
# sed -i 's/allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" \/>/allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|.*" \/> -->/g' ${INSTALL_DIR}/webapps/manager/META-INF/context.xml

# # Update Host Manager App context.xml
# sed -i 's/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"/g' ${INSTALL_DIR}/webapps/host-manager/META-INF/context.xml
# sed -i 's/allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" \/>/allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|.*" \/> -->/g' ${INSTALL_DIR}/webapps/host-manager/META-INF/context.xml

cat <<EOF > ${INSTALL_DIR}/webapps/manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
</Context>
EOF

cat <<EOF > ${INSTALL_DIR}/webapps/host-manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
</Context>
EOF

############################
# CREATE SYSTEMD SERVICE
############################
cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
Environment="CATALINA_PID=${INSTALL_DIR}/temp/tomcat.pid"
Environment="CATALINA_HOME=${INSTALL_DIR}"
Environment="CATALINA_BASE=${INSTALL_DIR}"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=${INSTALL_DIR}/bin/startup.sh
ExecStop=${INSTALL_DIR}/bin/shutdown.sh

User=${TOMCAT_USER}
Group=${TOMCAT_GROUP}
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

############################
# ENABLE & START TOMCAT
############################
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

############################
# CONFIGURE FIREWALL
############################
# ufw allow 8080/tcp || true

############################
# DISPLAY ACCESS INFO
############################
echo "----------------------------------------"
echo "Apache Tomcat ${TOMCAT_VERSION} Installed Successfully"
echo "Access URL: http://$(curl -s ifconfig.me):8080"
echo "Manager URL: http://$(curl -s ifconfig.me):8080/manager"
echo "Admin User: admin"
echo "Admin Password: redhat@123"
echo "----------------------------------------"

############################
# CLEANUP
############################
rm -f /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz
