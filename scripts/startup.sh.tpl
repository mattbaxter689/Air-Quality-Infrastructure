#!/bin/bash

apt-get update
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# install docker compose
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

USERNAME=$(logname)
usermod -aG docker "$USERNAME"

systemctl restart docker