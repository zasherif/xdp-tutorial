#!/bin/bash

# Ran on AWS with another interface "eth1 attached"

ovs-vsctl add-br ovsbridge
ip netns add netns0
ip netns add netns1
ip link add eth0-ns0 type veth peer name veth0
ip link add eth0-ns1 type veth peer name veth1
ip link set eth0-ns0 netns netns0
ip link set eth0-ns1 netns netns1
ovs-vsctl add-port ovsbridge veth0
ovs-vsctl add-port ovsbridge veth1
ip link set veth0 up
ip link set veth1 up
ip netns exec netns0 ip link set dev eth0-ns0 up
ip netns exec netns1 ip link set dev eth0-ns1 up

ip netns exec netns0 ip address add 20.0.0.2/24 dev eth0-ns0
ip netns exec netns1 ip address add 20.0.0.3/24 dev eth0-ns1

ip netns exec netns1 taskset -c 0-3 iperf -s -e -i 1 -P 4 > /dev/null 2>&1 &
ip netns exec netns0 taskset -c 0-3 iperf -c 20.0.0.3 -e -i 1 -P 4 | grep SUM
