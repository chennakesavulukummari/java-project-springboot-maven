#!/bin/bash

# Update the package index
sudo apt update -y

# Install Apache, Git, and utilities
sudo apt install apache2 git curl wget unzip tree -y

# Navigate to /opt and clone the repository
cd /opt/
sudo git clone https://github.com/kesavkummari/kesavkummari-website-code.git

# Move into the repo and copy files to the web root
cd /opt/kesavkummari-website-code/
sudo cp -pvr * /var/www/html/

# Optional: Ensure permissions are correct for the web server
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Restart Apache to ensure everything is fresh
sudo systemctl restart apache2