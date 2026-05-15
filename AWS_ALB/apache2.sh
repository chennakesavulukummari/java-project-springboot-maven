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

#rm -rf /var/www/html/* 

#echo "<html><body><h1>Welcome to Kesav's Website</h1><p>This is a placeholder page.</p></body></html>" | sudo tee /var/www/html/index.html

# Optional: Ensure permissions are correct for the web server
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Restart Apache to ensure everything is fresh
sudo systemctl restart apache2


#!/bin/bash

# Update the package index
sudo apt update -y

# Install Apache, Git, and utilities
sudo apt install apache2 git curl wget unzip tree -y

echo "<html><head><title>Welcome to Server-1</title></head><body style=\"background-color: #e8f4f8;\"><h1>Welcome to Server-1</h1><p>This is a placeholder page.</p></body></html>" | sudo tee /var/www/html/index.html

# Restart Apache to ensure everything is fresh
sudo systemctl restart apache2


#!/bin/bash

# Update the package index
sudo apt update -y

# Install Apache, Git, and utilities
sudo apt install apache2 git curl wget unzip tree -y

echo "<html><head><title>Welcome to Server-2</title></head><body style=\"background-color: #104805;\"><h1>Welcome to Server-2</h1><p>This is a placeholder page.</p></body></html>" | sudo tee /var/www/html/index.html

# Restart Apache to ensure everything is fresh
sudo systemctl restart apache2


echo "<html><head><title>Welcome AWS Courses</title></head><body style=\"background-color: #A52A2A;\"><h1>Welcome to AWS Courses</h1><p>This is a placeholder page.</p></body></html>" | sudo tee /var/www/html/courses/aws.html
