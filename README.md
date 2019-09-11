# Control plane setup

Docker compose creates the control plane docker environment:
```
                              +--------+-----------+
                              |                    |
                              |     accel-ppp      |
                              |                    |
                              +--------+-----------+
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
## Prerequisits

Presently the Control plane is implemented in a Docker-compose environment. So to deploy the Control Plane we need some modules and packeges as the prerequisits for installing Control plane.
1. Require 'docker' and 'docker-compose' 
```
apt install docker.io
apt install docker-compose
```
For more information about 'docker' and 'docker-compose' please follow the below link:

https://docs.docker.com/get-started/
https://docs.docker.com/compose/gettingstarted/

2. Require 'redis' module
```
pip3 install redis
```
For more information on 'redis' follow the below link:

https://redis.io/topics/quickstart 

## Deplying Control plane

The below steps lets you create the controlplane.
### Step 1

```
git clone https://github.com/dpdk-vbng-cp/docker-compose-cp.git
cd docker-compose-cp
```
### Run environment
Update submodule:
```
git submodule update --init
cd docker-accel-ppp
make
```
Create the containers and make them running
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
### Step 2
create vxlan to connect the control plane and Dataplane.
```
./vxlan_CP-DP.sh
```
### Step 3

To see the debug output of the dpdk-ip-pipeline CLI installing forwarding rules in the UL_VF and the DL_VF:
```
docker logs -f dockercomposecp_dpdk-ip-pipeline-cli_1 
```

