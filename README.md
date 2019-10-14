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

Currently the control plane is installed on Ubuntu via ansible.
To get started with ansible, please follow the official documentation:
- https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html

Apart from a basic understanding of ansible, you should have a working
environment with:

* Ubuntu 18.04 or newer
* python3
* python3-venv
* ansible (instructions on how to install are below)

## Prerequisites

### Install ansible on your local machine

You need to install the ansible python module on your local machine. There is no
need to install ansible on the remote hosts or targets. To install the tested
version of ansible, including all other needed python modules, please use a
virtual environment and the requirements.txt provided in this repo. If you are
running Ubuntu on your local machine and have `python3` and `python3-venv`
already installed, you can run:

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
cffi==1.12.3
cryptography==2.7
Jinja2==2.10.3
MarkupSafe==1.1.1
pycparser==2.19
PyYAML==5.1.2
six==1.12.0
```

## Ansible deployment

The ansible playbook in this repository will install all needed components
(including docker, docker-compose, redis and so on) on your target machine and
also apply the proper network configuration to them. To fit the deployment to
your environment, you need to create and adapt the ansible inventory file
(instruction on that are below) and add  control plane specific variable files
with unique names to the `control-plane-configs` folder.

### Writing your inventory

Add your target hosts, including some host specific variables to your inventory
file. An example can be found inside of this repository as `inventory.sample`.
Please copy this file to `inventory` and replace the names and variable values
according to your environment.

For more information on how to work with ansible inventories, please read the
official documentation provided here:
- https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html

### Writing specific control plane configs

To allow each control plane to connect to its target data plane deployment, you
need to specify multiple environment specific values for each control plane you
are deploying. Although multiple control planes can be deployed on the same
host, each of them might need a different configuration. This repo contains two
example files `cp1.yml` and `cp2.yml` in the `control-plane-configs` folder,
that can be used to derive the configuration you need for your deployment. The
name of the file will be used during the ansible-playbook run in the variable
`cp_name` to identify which control plane should be deployed.

### Running the ansible playbook

Before running the ansible playbook as described below, make sure you have the
correct host key fingerprint of your target machine added to your local
known_hosts file (the ansible ssh connections will fail otherwise).
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

NOTE:: This ansible_playbook also creates a vxlan interface to connect the
control plane and the data plane after all the docker containers are created.

### Cleaning up and redeploying

If you did major changes (especially to the docker-compose containers) you might
want to clean up the docker images, folders and containers to get a fresh
deployment without caching or any other strange artifacts in it. The ansible
playbook can be used to do this by providing the variable
"run_mode=clean_deploy" during the execution. An example command to clean up and
redeploy everything related to the control plane with the cp_name=cp1 would look
like this:

```
ansible-playbook -i inventory deploy_control_plane.playbook.yaml -k -u ubuntu -l server3 -e cp_name=cp1 -e run_mode=clean_deploy
```
 

### Helpful commands for debugging

To see the debug output of the dpdk-ip-pipeline CLI installing forwarding rules in the UL_VF and the DL_VF:

```
docker logs -f dockercomposecp_dpdk-ip-pipeline-cli_1
```

To be continued...

# Helpful links:

- https://docs.docker.com/get-started/
- https://docs.docker.com/compose/gettingstarted/

