#!/bin/bash

# This script separates the networks for traffic generation and reception on
# podwhale2. Moreover it creates a gateway between the BNG and the network
# intended to receive the traffic.

DEBUG=${DEBUG:-0}
[[ $DEBUG -gt 0 ]] && set -x

GW_NS=gw
GW_IFACE=enp134s0f1
INTERNET_NS=world
DOWNLINK_MAC1=00:00:00:01:00:01
DOWNLINK_MAC2=00:00:00:01:00:00
OVS_BRIDGE_GW=br-ovs-gw


# Deleting existing network namespaces and veth_interfaces

ip netns delete $GW_NS
ip netns delete $INTERNET_NS
ip link delete veth_gw_host
ip link delete veth_gw_ns
ip link add veth_gw_host type veth peer name veth_gw_ns
ip link set veth_gw_host up
ip link set veth_gw_ns up

# Ovs bridge set up to connect the enp134s0f1 and the veth_gw_ns
ovs-vsctl del-br $OVS_BRIDGE_GW
ovs-vsctl add-br $OVS_BRIDGE_GW
ovs-vsctl add-port $OVS_BRIDGE_GW $GW_IFACE
ovs-vsctl add-port $OVS_BRIDGE_GW veth_gw_ns
ip link set $GW_IFACE up
ip link set $OVS_BRIDGE_GW up
ip link set ovs-system up

# Create network namespace for GW
# Move interface to host network

ip netns add $GW_NS
ip netns exec $GW_NS ip link set veth_gw_host netns 1
ip link set veth_gw_host netns $GW_NS

# Create network namespace for INTERNET
ip netns add $INTERNET_NS

# Connect GW and INTERNET via veth pair
ip link set veth_gw_host netns $GW_NS
ip link add veth_gw type veth peer name veth_world
ip link set veth_gw netns $GW_NS
ip netns exec $GW_NS ip link set veth_gw_host down
ip netns exec $GW_NS ip link set dev veth_gw_host address AA:BB:CC:DD:EE:FF
ip netns exec $GW_NS ip link set veth_gw_host up
ip netns exec $GW_NS ip link set veth_gw up
ip link set veth_world netns $INTERNET_NS
ip netns exec $INTERNET_NS ip link set veth_world up

# Make GW a router, configure address and routes
ip netns exec $GW_NS sysctl -w net.ipv4.ip_forward=1
ip netns exec $GW_NS ip route add default dev veth_gw
ip netns exec $GW_NS ip route add 192.168.0.0/24 dev veth_gw_host
ip netns exec $GW_NS ip route add 192.168.10.0/24 dev veth_gw_host
ip netns exec $GW_NS ip address add 210.0.0.1/24 dev veth_gw

# Create static ARP entries for subnet1 (192.168.10.x addresses) hosts
for i in {2..100}; do
    ip netns exec $GW_NS arp -s 192.168.0.$i $DOWNLINK_MAC1
    #arp -s 192.168.0.$i $DOWNLINK_MAC
done
# Create static ARP entries for subnet2 (192.168.10.x addresses) hosts
for i in {2..100}; do
    ip netns exec $GW_NS arp -s 192.168.10.$i $DOWNLINK_MAC2
done
# Configure address and routes on INTERNET
ip netns exec $INTERNET_NS ip address add 210.0.0.100/24 dev veth_world
ip netns exec $INTERNET_NS ip route add 192.168.0.0/24 via 210.0.0.1
ip netns exec $INTERNET_NS ip route add 192.168.10.0/24 via 210.0.0.1

# Start iperf server in world
iperf_log=/tmp/iperf_server.log
rm -rf $iperf_log
touch $iperf_log
ip netns exec $INTERNET_NS iperf -su -D &>> $iperf_log

