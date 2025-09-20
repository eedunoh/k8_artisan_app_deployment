#!/bin/bash

# Update system packages
sudo yum update -y


# Increase max virtual memory map count required by Elasticsearch/SonarQube to prevent startup errors (This caused a serious error that made sonarqube container fail and keep restarting)
echo "vm.max_map_count=262144" >> /etc/sysctl.conf   # persist across reboots
sysctl -w vm.max_map_count=262144                   # apply immediately for current session


# Install Docker 
sudo yum install -y docker


# Start Docker service and enable on boot
sudo systemctl start docker
sudo systemctl enable docker


# Add ec2-user to Docker group (so we can use Docker without sudo)
sudo usermod -aG docker ec2-user


# Confirm Docker installed
docker --version


# Install Docker Compose:

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# Install libxcrypt-compat (Amazon Linux 2 requirement)
sudo yum install -y libxcrypt-compat

docker-compose --version

# install git
sudo yum update -y
sudo yum install git -y

# check git version
git --version



# Clone the repo and start docker-compose
cd /home/ec2-user
git clone https://github.com/eedunoh/k8_artisan_app_deployment.git


# Navigate into your Docker Compose files
cd /home/ec2-user/k8_artisan_app_deployment/vpc_and_cicd_deployments/dockerfiles


# Change ownership for Jenkins volume directory
sudo mkdir -p /home/ec2-user/jenkins_install
sudo chown -R 1000:1000 /home/ec2-user/jenkins_install


# Sleep to ensure Docker daemon is ready (optional)
sleep 20


# Run your Jenkins and Docker-in-Docker containers
docker-compose up -d