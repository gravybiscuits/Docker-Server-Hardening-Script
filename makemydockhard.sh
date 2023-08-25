#!/bin/bash

echo "Starting comprehensive Server Hardening and Docker Setup script..."

# Ensure the script exits on any command failure
set -e

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

echo "Starting server hardening process..."

# Configuration input
read -p "Enter the SSH port you'd like to use (default is 22): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

# Update and upgrade all packages
echo "Updating and upgrading packages..."
apt update && apt upgrade -y
apt autoremove -y

# Set up the firewall
echo "Setting up the firewall..."
apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow $SSH_PORT
ufw enable

# Install and enable intrusion detection (Fail2Ban)
echo "Installing and configuring Fail2Ban..."
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban

# Install required packages
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's GPG key with fingerprint check
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker CE
sudo apt-get update
sudo apt-get install -y docker-ce

# Install Docker Compose with version pinning
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Trivy for vulnerability scanning
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

## Docker Networking and Containers

echo "Starting Docker networking setup script..."

NETWORK_NAME="custom_bridge_network"

# Check if the custom network already exists
if [ -z "$(docker network ls | grep ${NETWORK_NAME})" ]; then
    # Create the custom bridge network
    docker network create ${NETWORK_NAME}
else
    echo "Network ${NETWORK_NAME} already exists."
fi

## Docker Networking and Containers

echo "Starting Docker networking setup script..."

# Configuration input for Docker containers
read -p "Do you want to run the Nginx container? (y/n): " RUN_NGINX
read -p "Do you want to run the MySQL container? (y/n): " RUN_MYSQL
read -p "Do you want to run the Redis container? (y/n): " RUN_REDIS

# If user wants to run Nginx, ask for version
if [ "$RUN_NGINX" = "y" ]; then
    read -p "Enter Nginx version (default is latest): " NGINX_VERSION
    NGINX_VERSION=${NGINX_VERSION:-latest}
fi

# If user wants to run MySQL, ask for version
if [ "$RUN_MYSQL" = "y" ]; then
    read -p "Enter MySQL version (default is 5.7): " MYSQL_VERSION
    MYSQL_VERSION=${MYSQL_VERSION:-5.7}
fi

# If user wants to run Redis, ask for version
if [ "$RUN_REDIS" = "y" ]; then
    read -p "Enter Redis version (default is latest): " REDIS_VERSION
    REDIS_VERSION=${REDIS_VERSION:-latest}
fi

# Image versions
NGINX_VERSION="latest"
MYSQL_VERSION="5.7"
REDIS_VERSION="latest"

# Run the Nginx container
NGINX_CONTAINER_NAME="nginx_server"
if [ -z "$(docker ps -a | grep ${NGINX_CONTAINER_NAME})" ]; then
    docker run -d --name ${NGINX_CONTAINER_NAME} --network ${NETWORK_NAME} -p 80:80 nginx:${NGINX_VERSION}
else
    echo "Nginx container ${NGINX_CONTAINER_NAME} already exists."
fi

# Run the MySQL container
MYSQL_CONTAINER_NAME="mysql_db"
echo -n "Enter a password for MySQL root: "
read -s MYSQL_ROOT_PASSWORD
echo ""  # Add a newline for cleaner output

if [ -z "$(docker ps -a | grep ${MYSQL_CONTAINER_NAME})" ]; then
    docker run -d --name ${MYSQL_CONTAINER_NAME} --network ${NETWORK_NAME} -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} mysql:${MYSQL_VERSION}
else
    echo "MySQL container ${MYSQL_CONTAINER_NAME} already exists."
fi

# Run the Redis container
REDIS_CONTAINER_NAME="redis_cache"
if [ -z "$(docker ps -a | grep ${REDIS_CONTAINER_NAME})" ]; then
    docker run -d --name ${REDIS_CONTAINER_NAME} --network ${NETWORK_NAME} redis:${REDIS_VERSION}
else
    echo "Redis container ${REDIS_CONTAINER_NAME} already exists."
fi

# Print container IPs
echo "Nginx container IP: $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${NGINX_CONTAINER_NAME})"
echo "MySQL container IP: $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${MYSQL_CONTAINER_NAME})"
echo "Redis container IP: $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${REDIS_CONTAINER_NAME})"

git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh

echo "Docker networking setup completed."
