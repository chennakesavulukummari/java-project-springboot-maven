#!/bin/bash
set -e

# Setup Hostname
sudo hostnamectl set-hostname "ansible.madeofmemories.com"

# Update the hostname part of Host File
echo "`hostname -I | awk '{ print $1 }'` `hostname`" >> /etc/hosts

# UPDATE & INSTALL PACKAGES
apt update -y
apt install -y curl wget vim git tree

apt update -y

# Install common packages for Ansible
apt install software-properties-common -y 

# Add Ansible PPA and Install Ansible
add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible
apt install ansible -y 

# DISPLAY ACCESS INFO
echo "----------------------------------------"
echo "Ansible Installed Successfully"
echo "----------------------------------------"

