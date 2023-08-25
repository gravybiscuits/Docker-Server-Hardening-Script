# hardenmydock
In summary, this script provides an automated way to harden server security settings, install Docker and some common containers, and check the Docker setup against security benchmarks.

tl:dr

Script:
UFW --> Fail2Ban --> Docker --> Trivy --> Ngnix Container --> MySQL Container --> Redis Container --> Docker Security Bench


Here's a breakdown of what the script does, step by step:

Prerequisite Checks:

Ensures the script will exit if any command fails (set -e).
Checks if the script is being run as the root user. If not, it prints a message asking the user to run the script as root and exits.


Server Hardening/Package Management:

Updates the package list (apt update).
Upgrades all packages to their latest versions (apt upgrade).
Removes unnecessary packages (apt autoremove).


Firewall Setup (UFW):

Installs the UFW (Uncomplicated Firewall) package.
Denies all incoming traffic by default.
Allows all outgoing traffic by default.
Explicitly allows incoming SSH traffic (port 22 by default).
There's a commented section indicating how to adjust for a custom SSH port.
Enables the firewall.


Intrusion Detection (Fail2Ban):

Installs Fail2Ban, a tool to block malicious IP addresses trying to breach the system.
Enables and starts the Fail2Ban service.


Docker Installation:

Installs required packages for Docker.
Adds Docker's official GPG key and sets up its repository.
Installs Docker CE (Community Edition).


Docker Compose Installation:

Fetches the latest version of Docker Compose.
Downloads and installs Docker Compose.


Trivy Installation:

Installs Trivy, a vulnerability scanner for Docker images.


Docker Networking and Containers Setup:

Introduces the Docker networking setup process.
Checks if a custom Docker bridge network (custom_bridge_network) exists. If not, it creates one.


Nginx Container:

Checks if an Nginx container named nginx_server exists. If not, it pulls the latest Nginx image and runs a container on the custom network, binding to port 80.


MySQL Container:

Prompts the user to enter a password for the MySQL root user.
Checks if a MySQL container named mysql_db exists. If not, it pulls the MySQL image (version 5.7) and runs a container on the custom network using the entered password for the root user.


Redis Container:

Checks if a Redis container named redis_cache exists. If not, it pulls the latest Redis image and runs a container on the custom network.
Prints the IP addresses of the Nginx, MySQL, and Redis containers within the Docker network.


Docker Security Benchmarking:

Clones the docker-bench-security repository from GitHub. This tool checks for common best-practices around deploying Docker containers in production.
Runs the Docker Bench Security script to assess the Docker setup's security.


Conclusion:
Prints a message indicating the completion of the Docker networking setup.
