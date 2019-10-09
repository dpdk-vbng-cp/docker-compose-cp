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
### Writing your inventory

Add your target hosts, including some host specific variables to your inventory
file. An example can be found inside of this repository as `inventory.sample`.
Please copy this file to `inventory` and replace the names and variable values
according to your environment.

### Running the ansible playbook

To run the ansible playbook after you followed all the steps above, just
execute the below command on your local machine:

```
ansible-playbook -i inventory deploy_control_plane.playbook.yaml -k -u ubuntu -l server3 -e cp_name=cp1
```

- `-i inventory`: specifies the inventory file that contains all the target
  hosts and the environment specific variables
- `deploy_control_plane.playbook.yaml`: is the name of the ansible playbook
  inside of this repo that will be executed
- `-k`: will ask for a connection password in case you are not able to
  authenticate with your ssh key to the remote server
- `-u ubuntu`: will set the username that is used to login to the remote server
  to `ubuntu` (change this if you are using another user to access your server)
- `-l server3`: will limit the ansible playbook run to the server `server3`
  specified in your inventory file
- `-e cp_name=cp1`: will define the unique name for your control plane that is
  used to differentiate between multiple docker-compose based deployments on one
  server. This name ("cp1") has to match the filename in the
  `control-plane-configs` folder on your local server. This file defines
  additional variables that are specific for each control plane.

For more information on ansible please check the official documentation here:
https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html

NOTE:: This ansible_playbook also creates a vxlan interface to connect the control plane and the data plane after all the docker containers are created.
 
