#!/bin/bash

# This script separates the networks for traffic generation and reception on
# podwhale2. Moreover it creates a gateway between the BNG and the network
# intended to receive the traffic.

DEBUG=${DEBUG:-0}
[[ $DEBUG -gt 0 ]] && set -x
OUTER_TAG=700
ACCESS_IFACE=enp132s0f0
OUTER_IFACE=vlan.$OUTER_TAG
INNER_TAG1=46
INNER_TAG2=3046
INNER_IFACE1=$OUTER_IFACE.$INNER_TAG1
INNER_IFACE2=$OUTER_IFACE.$INNER_TAG2

# Create vlans and network for access side
ip link set vlan.700 down
ip link delete link $OUTER_IFACE
ip link add link $ACCESS_IFACE $OUTER_IFACE type vlan proto 802.1Q id $OUTER_TAG
ip link set $OUTER_IFACE up
ip link add link $OUTER_IFACE $INNER_IFACE1 type vlan proto 802.1Q id $INNER_TAG1
ip link set $OUTER_IFACE.$INNER_TAG1 up
ip link add link $OUTER_IFACE $INNER_IFACE2 type vlan proto 802.1Q id $INNER_TAG2
ip link set $OUTER_IFACE.$INNER_TAG2 up
ip link set $ACCESS_IFACE up

# Access1 network with subnet 192.168.0.0/16
ip netns add access1
ip link set  $INNER_IFACE1 netns access1
ip netns exec access1 ip link set $INNER_IFACE1 up
ip netns exec access1 ip link set lo up

# Access2 network with subnet 192.168.10.0/16
ip netns add access2
ip link set  $INNER_IFACE2 netns access2
ip netns exec access2 ip link set $INNER_IFACE2 up
ip netns exec access2 ip link set lo up

# creating the ppp interfaces for access1

ip netns exec access1 pppd pty "pppoe -I $INNER_IFACE1 -T 80 -U \
-m 1412" noccp ipparam $INNER_IFACE1 linkname $INNER_IFACE1 noipdefault \
noauth default-asyncmap defaultroute hide-password updetach mtu 1492 \
mru 1492 noaccomp nodeflate nopcomp novj novjccomp \
lcp-echo-interval 40 lcp-echo-failure 3 user testing password password

ip netns exec access1 ip r add 210.0.0.0/24 dev ppp0
ip netns exec access1 iperf -u -c 210.0.0.100 -t 3600 -i 100 -b 100MB -t 120 &
# creating the ppp interface for access2

ip netns exec access2 pppd pty "pppoe -I $INNER_IFACE2 -T 80 -U \
-m 1412" noccp ipparam $INNER_IFACE2 linkname $INNER_IFACE2 noipdefault \
noauth default-asyncmap defaultroute hide-password updetach mtu 1492 \
mru 1492 noaccomp nodeflate nopcomp novj novjccomp \
lcp-echo-interval 40 lcp-echo-failure 3 user testing password password

ip netns exec access2 ip r add 210.0.0.0/24 dev ppp0
ip netns exec access2 iperf -u -c 210.0.0.100 -t 3600 -i 100 -b 100MB -t 120 &
      
