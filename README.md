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
To build the setup-environment, we need both the docker environment and also the accel-ppp setup.
The below steps lets you create the controlplane.
## Step 1
First clone the accel-ppp repo and build the accel-ppp environment for  docker-compose
```
git clone https://github.com/dpdk-vbng-cp/docker-accel-ppp
```
After cloning the repo follow the steps mentioned in the README of the "docker-accel-ppp" repo to create the build environment. 

## Step 2
Clone the docker-compose repo and install the submodules
```
git clone https://github.com/dpdk-vbng-cp/docker-compose-cp.git
```
### Run environment
Update submodule:
```
git submodule update --init
```
copy the accel-ppp files from the "Step 1"
```
rsync -r docker-accel-ppp/ docker-compose-cp/docker-accel-ppp/
```
Create the containers and make them running
```
docker-compose up -d
```
Stop environment:
```
docker-compose stop
```
Delete docker container:
```
docker-compose rm
```
create vxlan to connect either the dataplane or the load generator. Depends if you want to use the PF_INIT split senario or splited traffic at the client side senario.
```
./vxlan_dell100.sh
```
## Step 3


To see the debug output of the dpdk-ip-pipeline CLI installing forwarding rules in the UL_VF and the DL_VF:
Start the bngs in the dataplane and then follow the below commands before starting the "pppd" client in the load generator.
```
cd /root/docker-compose-cp/bng-utils/dpdk-ip-pipeline-cli

python3 dpdk-ip-pipeline-cli.py   --redis-host localhost --redis-port 6379 --telnet-host-uplink smicro-unten.labor2.bisdn.de --telnet-port-uplink 8094 
--telnet-host-downlink smicro-unten.labor2.bisdn.de --telnet-port-downlink 8086

```
