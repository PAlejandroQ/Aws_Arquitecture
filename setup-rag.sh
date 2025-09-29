#!/bin/bash
# AWS RAG Laboratory - EC2 Ubuntu Initialization Script
# This script runs automatically when the EC2 instance starts
# It installs Docker and deploys the RAG application using Docker Compose

# 1. Update system and install basic dependencies
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release git

# 2. Install Docker
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group (optional, for convenience)
sudo usermod -aG docker ubuntu

# 3. Clone the RAG project from GitHub
cd /home/ubuntu
git clone https://github.com/PAlejandroQ/Puc_RAG.git rag-demo
chown -R ubuntu:ubuntu rag-demo
cd rag-demo

# 4. Start the RAG application using Docker Compose
# This will build and start all services: Ollama, Elasticsearch, and the FastAPI app
sudo docker compose up --build -d

# Script ends here - the application continues running in Docker containers
