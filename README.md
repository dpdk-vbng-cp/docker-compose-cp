# Control plane setup

Docker compose creates the control plane docker environment:
```
                              +--------+-----------+    +------------------+
                              |                    |    |                  |
                              |     accel-ppp      |----+     Radius       |
                              |                    |    |                  |
                              +--------+-----------+    +------------------+
                                       |
                                       |
                              +--------+-----------+
                              |                    |
                              |    redis pub/sub   |
                              |                    |
                              +--------+-----------+
                                       |
                                       |
                               +-------+------------+
                               |                    |
                               |dpdk-ip-pipeline-cli|
                               |                    |
                               +--------+-----------+
                                        |
                                  +-----+--------+
                                  |              |
                       +----------+-----+   +----+-----------+    
                       | telnet_uplink  |   | telnet_downlink|
                       +----------------+   +----------------+     
```
## Dependencies

Currently the control plane is installed on an Ubuntu platform.

* Ubuntu 18.04 or newer
* python3
* pip3

## Prerequisits

Presently the control plane is implemented in a Docker-compose environment. So to deploy the control plane we need some modules and packeges as the prerequisits for installing the control plane.
1. Install 'docker' and 'docker-compose'
```
sudo apt update
sudo apt install -y docker-compose docker.io python3-pip
sudo usermod -a -G docker <groupname>
```
We create the usergroup for 'docker', else we require to start everytime with root as 'docker'
uses the 'Unix Socket'.
For more information about 'docker' and 'docker-compose' please follow the below link:

https://docs.docker.com/get-started/

https://docs.docker.com/compose/gettingstarted/

2. Require 'redis' module
```
pip3 install redis
```
For more information on 'redis' follow the below link:

https://redis.io/topics/quickstart

## Deploying control plane

The below steps lets you create the control plane.
### Cloning the modules from the git repo

```
git clone https://github.com/dpdk-vbng-cp/docker-compose-cp.git
cd docker-compose-cp
```
### Run the environment
Update submodule:
```
git submodule update --init
cd docker-accel-ppp
make build
cd ..
```
Create the containers and start them
```
docker-compose up -d
```
Stop environment:
```
docker-compose stop
```
Delete docker containers:
```
docker-compose rm
```
### Connecting CP and DP
create vxlan to connect the control plane and dataplane.
```
./vxlan_CP-DP.sh
```
### Debug output and logs to check the correct rules, written in the UL and DL VFs

To see the debug output of the dpdk-ip-pipeline CLI installing forwarding rules in the UL_VF and the DL_VF:
```
docker logs -f dockercomposecp_dpdk-ip-pipeline-cli_1
```
# Vagrant Box Deployment

This repo contains a vagrant folder to setup the full docker-compose control plane in a virtual machine. To start this, just run:

```
cd vagrant
vagrant up
```
For more details on Vagrant, please follow the below link:

https://www.vagrantup.com/intro/index.html
