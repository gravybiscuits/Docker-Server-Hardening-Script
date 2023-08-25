#!/bin/bash

# Stop and remove all Docker containers (if Docker is installed)
if command -v docker &> /dev/null; then
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
    sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce
    sudo rm -rf /var/lib/docker /etc/docker
    sudo rm /etc/apparmor.d/docker
    sudo groupdel docker
    sudo rm -rf /var/run/docker.sock
fi

# Remove common packages
sudo apt-get purge -y apache2* mysql* php*

# Autoremove to clean up any unnecessary packages
sudo apt-get autoremove -y

# Clear apt cache
sudo apt-get clean

echo "Uninstallation steps completed."
