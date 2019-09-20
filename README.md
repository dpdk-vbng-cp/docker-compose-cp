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

Currently the control plane is implemented in a Docker-compose environment. So to deploy the control plane we need some modules and packages as the prerequisits.

1. Install 'docker' and 'docker-compose'

```
sudo apt update
sudo apt install -y docker-compose docker.io python3-pip
sudo usermod -a -G docker <username>
```
We need to add our user to the docker group to allow it access to the docker socket, which is required to use all docker commands.
For more information about 'docker' and 'docker-compose' please follow the below link:

https://docs.docker.com/get-started/

https://docs.docker.com/compose/gettingstarted/

2. Install 'redis' module

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
Create vxlan to connect the control plane and data plane.

```
./vxlan_CP-DP.sh
```
### Debug output

To see the debug output of the dpdk-ip-pipeline CLI installing forwarding rules in the UL_VF and the DL_VF:

```
docker logs -f dockercomposecp_dpdk-ip-pipeline-cli_1
```
# Vagrant Box Deployment

This repo also contains a vagrant folder to setup the full docker-compose control plane in a virtual machine. To start this, just run:

```
cd vagrant
vagrant up
```
For more details on Vagrant, please follow the below link:

https://www.vagrantup.com/intro/index.html

# Ansible Deployment

This repo also contains an Ansible module which creates the control plane from your local machine. The steps to add your hosts/targets and executing the ansible_playbook on them are below:

### Install ansible in your local machine 

you need to install the ansible module in your local machine. There is no need to install ansible in the remote hosts or targets

```
sudo apt install ansible
```
### Adding hosts/targets to your ansible known hosts file
```
sudo vi /etc/ansible/hosts

```
add your specific hostnames and variables for your target machine. Here is an example of how the file looks like. You can use your own inventory for ansible_playbook as well.
```
[servers]
<hostname1> ansible_host=xx.xx.xx.xx (ip of your host) hostname_dataplane=<hostname of your data plane 1>
#server3 ansible_host=203.0.113.113

[servers:vars]
dataplane_uplink_port1=<port number of uplink>
```

if multiple hosts need to be targeted, then this file needs to be updated with the hostnames and the IP addresses of the new servers, along with the required relevant variables

### Executing ansible_playbook

```
ansible-playbook deploy_control_plane.playbook.yaml -k -u <username> -l <hostname>
```

provide the 'username' and the 'hostname' of the server you are targeting. The 'hostname' is the name that you provided as a variable in the file "/etc/ansible/hosts". For more information on Ansible please follow the link below.

https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html

NOTE:: This ansible_playbook also creates a vxlan interface to connect the control plane and the data plane after all the docker containers are created.
 
