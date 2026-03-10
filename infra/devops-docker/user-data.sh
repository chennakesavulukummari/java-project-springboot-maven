#!/bin/bash
set -e

# Setup Hostname
sudo hostnamectl set-hostname "docker.madeofmemories.com"

# Update the hostname part of Host File
echo "`hostname -I | awk '{ print $1 }'` `hostname`" >> /etc/hosts

# UPDATE & INSTALL PACKAGES
apt update -y
apt install -y curl wget vim git tree

# Install Docker on Ubuntu Server
sudo apt-get install docker.io -y 

# Enable Docker For Ubuntu User
sudo usermod -aG docker ubuntu

# Grant Access Docker Socket
sudo chmod 777 /var/run/docker.sock

# ENABLE & START docker
systemctl enable docker
systemctl start docker

# DISPLAY ACCESS INFO
echo "----------------------------------------"
echo "Docker Installed Successfully"
echo "----------------------------------------"

