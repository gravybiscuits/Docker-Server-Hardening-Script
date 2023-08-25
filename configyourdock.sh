#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Backup Docker configurations
echo "Backing up Docker configurations..."
sudo tar czvf docker-backup.tar.gz /var/lib/docker/ || handle_error "Failed to backup Docker configurations."

# Ask user for new bridge network name
read -p "Enter a name for the new bridge network: " network_name

# Check if the network name already exists
if sudo docker network ls | grep -wq $network_name; then
    handle_error "A network with the name $network_name already exists. Please choose another name."
fi

# Create a new bridge network
echo "Creating new bridge network named $network_name..."
sudo docker network create --driver bridge $network_name || handle_error "Failed to create new bridge network."

# Get all container IDs
containers=$(sudo docker ps -a -q)

for container in $containers; do
    # Check if container is connected to the default bridge
    if sudo docker inspect $container | grep '"NetworkMode": "default"'; then
        # Disconnect container from the default bridge
        sudo docker network disconnect bridge $container || handle_error "Failed to disconnect container $container from default bridge."
    fi

    # Connect container to the new bridge
    sudo docker network connect $network_name $container || handle_error "Failed to connect container $container to $network_name."
done

# Restart all containers
for container in $containers; do
    sudo docker restart $container || handle_error "Failed to restart container $container."
done

echo "Containers have been reconfigured to use the new bridge named $network_name."
