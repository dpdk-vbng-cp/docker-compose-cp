#!/bin/bash
# This script creates and configures vxlan on the control plane.
 
set -x

VXLAN_ID=200
VXLAN_IFACE=vxlan$VXLAN_ID
LOCAL=172.16.248.198 # IP of the host conatining the CP
REMOTE=172.16.248.152 # IP of the host containing the DP

DOCKER_BR=br-$(docker network ls -fname=dockercomposecp_1_accel_network -q)

ip l del $VXLAN_IFACE
ip l add $VXLAN_IFACE type vxlan id $VXLAN_ID dstport 4789 local $LOCAL remote $REMOTE
ip l set $VXLAN_IFACE master $DOCKER_BR
ip l set $VXLAN_IFACE up
