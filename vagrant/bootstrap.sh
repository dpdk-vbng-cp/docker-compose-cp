#!/bin/bash
sudo apt update
sudo apt install -y docker-compose docker.io python3-pip
sudo usermod -a -G docker vagrant
pip3 install redis
git clone https://github.com/dpdk-vbng-cp/docker-compose-cp.git
cd docker-compose-cp
git submodule update --init
cd docker-accel-ppp/
make build
cd ..
docker-compose up -d
