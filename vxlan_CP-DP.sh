#!/bin/bash
# This script creates and configures vxlan on the control plane.

set -x

VXLAN_ID=200
VXLAN_IFACE=vxlan$VXLAN_ID
# podwhale2.labor2.bisdn.de
LOCAL=172.16.248.114
# podwhale3.labor2.bisdn.de
REMOTE=172.16.248.113
DOCKER_BR1=br-$(docker network ls -fname=cp1_1_accel_network -q)
DOCKER_BR2=br-$(docker network ls -fname=cp2_1_accel_network -q)
# Uncomment the below instruction to use control traffic split at the client end.

ip l del $VXLAN_IFACE
ip l add $VXLAN_IFACE type vxlan id $VXLAN_ID dstport 4789 local $LOCAL remote $REMOTE
ip link del veth0 type veth peer name veth1
ip link del veth2 type veth peer name veth3
ip link add veth0 type veth peer name veth1
ip link add veth2 type veth peer name veth3
ip l set veth0 up
ip l set veth1 up
ip l set veth2 up
ip l set veth3 up
brctl addbr br0
brctl addif $DOCKER_BR1 veth0
brctl addif br0 veth1
brctl addif $DOCKER_BR2 veth2
brctl addif br0 veth3
ip l set $VXLAN_IFACE master br0
ip l set $VXLAN_IFACE up

