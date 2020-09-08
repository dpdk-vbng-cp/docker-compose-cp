# BNG for Central Office in a Box (COB) setup

Docker compose creates the control plane docker environment:

```
                            
			      +--------+-----------+      +------------------+
                              |                    |      |                  |
                              |     accel-ppp      |<---->+     Radius       |
                              |                    |      |                  |
                              +--------+-----------+      +------------------+
                                       |
                                       |
				       |	
                              +--------+-----------+
                              |                    |
                              |    redis server    |
                              |                    |
                              +--------+-----------+
                                       |Forwarding 
				       |Entries
                                       |
                               +-------+------------+
                               |                    |
                               |   redis client     |
                               |                    |
                               +--------+-----------+
                                        |
                                  +-----+
                                  |              
  +-------+-----+      +-------+--------+        +----+-----------+    
  | bngu-pfcp   |----->|    bngc-pfcp   |<------>|   bngc-app     |
  |             |<-----|                |        |                |
  +-------+-----+      +----------------+        +----------------+ 
				
    
```

## Prerequisites

### Server requirements

The Control-plane is deployed in multiple docker containers. While Docker is supported 
in multiple OS architectures, we recommend using a Linux distribution in the host where 
the Control-plane is deployed. In addition, the target host must have a SSH server 
running and at least one user that can be remotely accessed through SSH with super user privileges.

The following instructions for the PON Portal installation were tested on a server 
running [Ubuntu Server 20.04.1 LTS](https://releases.ubuntu.com/20.04/).

### Local requirements

Currently the control plane for the COB setup is installed in Ubuntu via ansible.
To get started with ansible, please follow [the official documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html).

Apart from a basic understanding of ansible, you should have a working
environment with:

* Ubuntu 18.04 or newer
* python3
* python3-venv
* ansible (instructions on how to install are below)

#### Install ansible on your local machine

You need to install the ansible python module on your local machine. There is no 
need to install ansible on the remote hosts or targets (the only requirement for 
these is a working python3 environment).
We recommend using a virtual environment to install all required python dependencies. 
After having python3 and python3-venv installed, a virtual environment can be created 
with the following command:

```
python3 -m venv my-virtualenv
```
To active the the created virtualenv run:

```
source my-virtualenv/bin/activate
```

And finally to install all needed python modules into the actived virtualenv run:

```
pip install -r requirements.txt
```

After you have followed all three steps from above, running the command `pip
freeze` should look exactly like this:

```
ubuntu@localhost:~$ pip freeze
ansible==2.8.5
asn1crypto==1.1.0
cffi==1.13.0
cryptography==2.7
dnspython==1.16.0
Jinja2==2.10.3
MarkupSafe==1.1.1
pycparser==2.19
PyYAML==5.1.2
six==1.12.0
```

#### Running docker on your target machine behind a proxy 

If your target machine is running behind a proxy or does not have direct access
to the internet and more specifically to the ubuntu apt repositories, you need
to add this proxy also for docker. To allow docker running on the target machine
to pull images from dockerhub (which we need to pull all the base images), you
have to modify the docker service like documented in the official 
[docker proxy page](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy).

To allow docker containers to install new packages during runtime (which is
needed to install the proper kernel header files to build kernel modules in our
case) you also need to add your proxies for the docker client like documented
[docker network proxy documantation](https://docs.docker.com/network/proxy/).

### Control Plane setup

The Control plane for the Central Office in a Box (COB) setup contains the below 
components running in docker containers:

– One or multiple accel-ppp container
– One Redis server in a container
– One PFCP BNG CP in a container
– One Radius server in a container
– One mysql database in a container

![BNG Control Plane](/home/taushif/vBNG_project/CP_BNG.png)

Whenever any of the ‘accel-ppp’ containers receive a PADI request from the client, 
it communicates with the ‘Radius’ container for the user authentication and authorization. 
The Radius server looks up for available IP addresses in the mysql database to assign 
the IP address for the user. During the session establishment the messages are published 
to the ‘Redis’ container, which are subscribed by the ‘PFCP BNG CP’ container. 
The ‘PFCP BNG CP’ container has PFCP associations established with the ‘PFCP BNG UP’ 
containers, which are running in the Data plane server. The ‘PFCP BNG CP’ container 
forwards the command to write specific forwarding rules into the DPDK-BNG containers 
running in the Data plane.

#### Ansible deployment

The ansible playbook ‘deploy_bng_control_plane.playbook.yaml’, in this branch of the 
repository, will install all needed components on your target machine for the 
Control plane and also apply the proper network configuration to them. To fit 
the deployment to your environment, you need to create and adapt the ansible 
inventory file and add control plane specific variables with unique names and 
its values to the ‘inventories’ directory. For our deployment we have 
a `vm-inventory-mysql.yml` file inside the ‘inventories’ folder which deploys 
all the required components. A brief description of the variables of the 
inventory file in provided below:

- hosts – the target control plane FQDN/IP address

- vars:
         – ‘run_mode’ can have three values ‘deploy’, ‘clean’, ‘clean deploy’. 
‘deploy’ is set when the components of the Control plane are deployed for the first time. 
To clean the old containers ‘run_mode = clean’ and to clean and restart all 
the containers ‘run_mode=clean_deploy’
	 – ‘mysql_root_password’ is the password to access the database
         – ‘mysql_database’ is the name of the sql database
 	 – ‘radius_mysql_user’ is the name of the user that radius uses to authenticate with the mysql database
	 – ‘radius_mysql_password’ is the password for the `radius_mysql_user` to access the database
 	 – ‘redis_host’ is the host where the redis server is running
 	 – ‘redis_port’ is the port where the redis server is listening for messages
	 – ‘bngc_ip_addr’ is the IP address of the PFCP BNG CP container
     	 – ‘net_prefix’ is the subnet of the IP address range
	 – ‘bngu_endpoints’ provides the parameters to connect PFCP BNG CP to 
different PFCP BNG UP containers running in the data plane:
		- bngu_ip: IP address of the PFCP BNG UP instance
		- nas_id: Unique NAS Identifier used by the respective accel-pppd instance in the control plane.

- docker networks values – the different containers need to be accessible for each other. 
We create a docker subnetwork for the communication between the docker containers. 
This value should not be modified by the user, unless it conflicts with an existing 
network in the control plane host.

- CP instances – presently in the setup each of the ‘accel-ppp’ containers is responsible 
and connected to each BNG (UL/DL pair) container. The MAC address of the ‘accel-ppp’ 
container should be the same as the DPDK BNG UL MAC address. The ‘outer_tag’  
here is of the interfaces the ‘accel-ppp’ container creates. In the present setup the 
accel-ppp container is created with 4000 interfaces for the incoming double tagged traffic. 
The ip range values are used to configure the radius IP pools that will be distributed 
to the clients.

There are three types of variables nested in “cp_instances”. Some variable values which 
are aligned to the dataplane containers are fixed and cannot be modified. Those variables 
are commented in the inventory file. Here in the README we have the other two types:

	1. Can be modified:
		- cp_n: is the accel-ppp instance number 
		- accel_ppp_ip: is the ip address of the accel-ppp container.
		- ip_subnet_accel_network: is the secondary docker network for the 
different control plane components to communicate with each other. 
		- ip_range_start: is the start of the ip_pool for assigning the 
ip_addresses to the clients. The start value can take any private ip address values.
		- ip_range_end: is the end of the ip_pool for the particular CP instance. 
The recommended minimum value will be 4096 ip_addresses starting from the ‘ip_range_start’. 
This is because one accel-ppp container is configured to handle 4096 clients that is 4096 
ip_addresses. But the configuration of accel-ppp can be changed to a shorter support range, 
which then concludes a shorter ip_address range.  
		- vxlan_id: is the id of the vx-tunnel for the control traffic where this 
particular CP instance communicates with the BNG. In our present setup one vxlan tunnel 
serves two accel-ppp and two ip_pipeline container pairs. 		
		- vxlan_iface: is the name of the vxlan tunnel 
		- outer_tag: is the outer vlan id of the interfaces created inside 
the accel-ppp container
		- veth_iface: is the end of the veth_pair which connects to the docker 
bridge. The veth_iface name can be renamed as any other name.
		- veth_peer: is the other end of the veth pair which connects to the 
linux bridge to the control plains. 
		- bridge_to_cps: is the bridge which connects docker-bridge and the accel-ppp containers.

	2. Recommended not to be modified:
 		- nas_identifier: is the identification values of different accel-ppp 
containers and is aligned with one specific ip_pipeline container pair. 
		
NOTE: Before running the ansible playbook as described below, make sure you have the correct 
host key fingerprint of your target machine added to your local known_hosts file (the ansible
ssh connections will fail otherwise). 

##### Initial control plane deployment

To start the control plane for the first time on your target machine, please change directory 
to ‘docker-compose-cp’ and execute the below command:

```
ansible-playbook -i inventories/vm-inventory-mysql.yml deploy_bng_control_plane.playbook.yaml 
-u ubuntu -e setup_all=yes -e run_mode=deploy
```
- `-e setup_all=yes`: With the value set to ‘yes’ all the containers (accel-ppp, Redis, Radius, 
PFCP BNG CP, mysql) will be created and started. There are also variables like →  ‘setup_docker, 
setup_redis, setup_mysql, setup_radius, setup_pfcp_cp, setup_accel_pppd’ where you can instantiate 
individual containers by setting the value to ‘yes’
- `-i inventory`: specifies the inventory file that contains all the target
  hosts and the environment specific variables
- `deploy_bng_control_plane.playbook.yaml`: is the name of the ansible playbook
  inside of this repo that will be executed
- `-u ubuntu`: will set the username that is used to login to the remote server
  to `ubuntu` (change this if you are using another user to access your server)
- `-e run_mode=deploy`: will fresh deploy the control plane with all its containers, bridges, vxlans required

##### Cleanup environment variables

An environment variable called run_mode can be used to instruct ansible to stop all containers 
and exit, or to stop all containers before they are started. It's default value is set to deploy, 
but it can be set to the following values:

- `-e run_mode=clean`: will clean the control plane and all its containers, bridges, vxlans
- `-e run_mode=clean_deploy`: will first clean the old control plane and all its containers,
bridges, vxlans and then deploy it freshly

To restart the control plane and clean up the old containers execute the command below:

```
ansible-playbook -i inventories/vm-inventory-mysql.yml deploy_bng_control_plane.playbook.yaml 
-u ubuntu -e setup_all=yes -e run_mode=clean_deploy
```

### PFCP User Plane setup

The PFCP application has the User Plane side (PFCP BNG UP) which communicates with 
DPDK IP PIPELINE (The virtual BNG’s) and also has the association with the PFCP BNG CP. 
PFCP BNG UP connects to the telnet counter part of the DPDK and forwards the commands to 
write the packet forwarding rules inside the pipelines. Each UL/DL pair of BNG containers 
connect to an individual PFCP BNG UP. Multiple PFCP BNG UP containers can run at the same 
time and communicate with the single PFCP BNG CP in the control plane.

![BNG PFCP User Plane](/home/taushif/vBNG_project/PFCP_USER_Plane.png)

Before we start the PFCP BNG UP container the DPDK BNGS needs to be up and running. 
Please follow the [DPDK BNG setup](https://gitlab.bisdn.de/ansible/ansible-vbng/-/tree/dell_630_configs) 
repo readme to setup your BNG containers.

#### Writing specific data plane specific PFCP BNG UP container configs

The bngu folder has its own inventory files that are used to specify the data 
plane configuration. The file `bng-2-up-inventory.yml` has the values from the 
dataplane configs: 

- hosts – the target data plane FQDN/IP address

- vars:
         – ‘run_mode’ can have three values ‘deploy’, ‘clean’, ‘clean deploy’. 
‘deploy’ is set when the components of the Control plane are deployed for the first time. 
To clean the old containers ‘run_mode = clean’ and to clean and restart all the containers 
‘run_mode=clean_deploy’
	 – ‘dpdk_host’ is the hostname of the dataplane
         – ‘bngc_ip_addr’ is the IP address of the PFCP BNG CP container
     	 – ‘net_prefix’ is the subnet prefix of the network used between the PFCP containers
- up_instances’: contains the variable values for each PFCP BNG UP instance running in 
the dataplane. Each instance is hooked to the ‘telnet’ counter part of the dpdk pipeline:
- ‘container_name’ is the name of the PFCP BNG UP as there can be multiple PFCP BNG UP 
containers talking to different BNG instances.
         - ‘bngu_ip_addr’ is the ip address of PFCP BNG UP
 	 - ‘upstream_dpdk_port’ is the exposed port number from the telnet hook of the 
DPDK Uplink container
 	 - ‘downstream_dpdk_port’ is the exposed port number from the telnet hook of 
the DPDK Downlink container
	 - ‘gateway_mac_address’ is the MAC address of the gateway to the CORE network/ Internet
     	 - ‘gateway_ip_address’ is the IP address of the gateway to the CORE network/Internet
	 - ‘downstream_mac_address’’ is the MAC address of the DPDK downlink container

NOTE: Before running the ansible playbook as described below, make sure you have the
correct host key fingerprint of your target machine added to your local known_hosts 
file (the ansible ssh connections will fail otherwise). To run the ansible playbook 
after you followed all the steps above, just execute the below command on your local machine:

#### Data plane PFCP BNG UP

To start the PFCP BNG UP containers for the first time on your target machine, please 
change directory to ‘docker-compose-cp/bngu’ and execute the command below:

##### Fresh deployment of PFCP BNG UP

```
ansible-playbook -i inventories/bng-2-up-inventory.yml deploy_bngu_containers.playbook.yaml
 -u ubuntu -e run_mode=deploy
```
- `-i inventory`: specifies the inventory file that contains all the target
  hosts and the environment specific variables
- `deploy_bngu_containers.playbook.yaml`: is the name of the ansible playbook
  inside of this repo that will be executed
- `-u ubuntu`: will set the username that is used to login to the remote server
  to `ubuntu` (change this if you are using another user to access your server)

##### Cleanup environment variables

An environment variable called run_mode can be used to instruct ansible to stop all 
containers and exit, or to stop all containers before they are started. It's default 
value is set to deploy, but it can be set to the following values:

 - `-e run_mode=clean`: will clean the control plane and all its containers, bridges, vxlans
 - `-e run_mode=clean_deploy`: will first clean the old control plane and all its containers, 
bridges, vxlans and then deploy it freshly

To restart the control plane and cleaning up the old containers execute the below command:

```
ansible-playbook -i inventories/bng-2-up-inventory.yml deploy_bngu_containers.playbook.yaml
 -u ubuntu -e run_mode=clean_deploy
```
### Helpfull Links

For more information on ansible please check the [Ansible Official documentation](
https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html)

For more information on docker please check the [Docker Official documentation](
https://docs.docker.com/get-started/)

