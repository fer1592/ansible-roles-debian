#!/bin/bash
set -eEuf -o pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <playbook-file>"
    exit 1
fi

playbook_file=$1

# Get current user
CURRENT_USER=$(whoami)

# Add user to the 'sudo' group and grant NOPASSWD access for all commands
echo "Configuring passwordless sudo for user: $CURRENT_USER. Make sure sudo is installed and you are able to call sudo (debian 13 might not installed nor configured sudo)"
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/${CURRENT_USER}" > /dev/null

# Update packages first
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y python3-debian python3-pip

# Create a new venv if it doesn't exist
if [ ! -d "venv" ]; then
    mkdir -p venv
    python3 -m venv venv/ansible
fi

# Install ansible if it is not already installed
if ! command -v ansible &> /dev/null; then
    venv/ansible/bin/pip install --upgrade pip
    venv/ansible/bin/pip install cryptography --only-binary cryptography
    venv/ansible/bin/pip install ansible
fi

# Upgrade the community.docker collection. Required otherwise the older version will be used, which do not support the docker-image module
venv/ansible/bin/ansible-galaxy collection install -U community.docker

# Run the ansible playbook for the initial configuration
venv/ansible/bin/ansible-playbook -i inventories/local/hosts "${playbook_file}"
