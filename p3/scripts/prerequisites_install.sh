#!/bin/bash
set -e

echo "Prerequisites installations"

# Packet update
sudo apt-get update && sudo apt-get upgrade -yqq

# Docker installation
if ! command -v docker &> /dev/null; then
    echo "--------------- Installing Docker ... ---------------"

    # Install prerequisites
    sudo apt-get install -yqq \
        ca-certificates \
        curl \
        wget \
        git \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker's APT repository
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Update package index with new repo
    sudo apt-get update -qq

    # Install Docker packages
    sudo apt-get install -yqq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add users to docker group
    sudo groupadd docker || true
    sudo usermod -aG docker $USER

else
    echo "Docker is already installed"
fi

# k3d installation
if ! command -v k3d &> /dev/null; then
    echo "--------------- Installing dk3d ... ---------------"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d is already installed"
fi

# kubectl installation
if ! command -v kubectl &> /dev/null; then
    echo "--------------- Installing dkubectl ... ---------------"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl is already installed"
fi

echo "--------------- ✅ Installation Complete ---------------"
echo " You may relog into your session to be able to use Docker without 'sudo' "