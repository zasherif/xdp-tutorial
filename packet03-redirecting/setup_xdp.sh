#!/bin/bash

# To be ran inside "xdp-tutorial/packet03-redirecting"
eval $(../testenv/testenv.sh alias)
make

t setup --name=test

t setup --name right
t setup --name left

t load -n left -- -F --progsec xdp_redirect_map
t load -n right -- -F --progsec xdp_redirect_map

t exec -n left -- ./xdp_loader -d veth0 -F --progsec xdp_pass
t exec -n right -- ./xdp_loader -d veth0 -F --progsec xdp_pass

t redirect right left

ip netns exec left ifconfig veth0 10.0.0.2 netmask 255.255.255.0
ip netns exec right ifconfig veth0 10.0.0.3 netmask 255.255.255.0

ip netns exec left ethtool --offload veth0 rx off tx off
ip netns exec right ethtool --offload veth0 rx off tx off

ip netns exec left sysctl -w net.ipv4.tcp_mtu_probing=2
ip netns exec right sysctl -w net.ipv4.tcp_mtu_probing=2

ip netns exec right taskset -c 0-3 iperf -s -e -i 1 -P 4 > /dev/null 2>&1 &
ip netns exec left taskset -c 0-3 iperf -c 10.0.0.3 -e -i 1 -P 4 | grep SUM
