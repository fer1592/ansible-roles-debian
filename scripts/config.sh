#!/bin/bash
set -eEuf -o pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <playbook-file>"
    exit 1
fi

playbook_file=$1

# Update packages first
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y python3-debian python3-pip python3-venv

# Create a new venv if it doesn't exist
if [ ! -d "venv" ]; then
    mkdir -p venv/ansible
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
venv/ansible/bin/ansible-playbook -i inventories/local/hosts "${playbook_file}" --vault-password-file ~/.ansible/vault-password-file
