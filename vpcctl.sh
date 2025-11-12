#!/bin/bash
# vpcctl.sh - Build and manage a virtual private cloud using Linux namespaces

ACTION=$1

create_vpc() {
  echo "[+] Creating network namespaces..."
  sudo ip netns add priv
  sudo ip netns add pub
  sudo ip netns add r1

  echo "[+] Creating veth pairs..."
  sudo ip link add veth-priv type veth peer name veth-r1-priv
  sudo ip link add veth-pub type veth peer name veth-r1-pub

  echo "[+] Connecting interfaces to namespaces..."
  sudo ip link set veth-priv netns priv
  sudo ip link set veth-pub netns pub
  sudo ip link set veth-r1-priv netns r1
  sudo ip link set veth-r1-pub netns r1

  echo "[+] Assigning IP addresses..."
  sudo ip netns exec priv ip addr add 10.0.1.10/24 dev veth-priv
  sudo ip netns exec r1 ip addr add 10.0.1.1/24 dev veth-r1-priv
  sudo ip netns exec r1 ip addr add 10.0.2.1/24 dev veth-r1-pub
  sudo ip netns exec pub ip addr add 10.0.2.10/24 dev veth-pub

  echo "[+] Bringing interfaces up..."
  sudo ip netns exec priv ip link set veth-priv up
  sudo ip netns exec pub ip link set veth-pub up
  sudo ip netns exec r1 ip link set veth-r1-priv up
  sudo ip netns exec r1 ip link set veth-r1-pub up
  sudo ip netns exec priv ip link set lo up
  sudo ip netns exec pub ip link set lo up
  sudo ip netns exec r1 ip link set lo up

  echo "[+] Configuring routing..."
  sudo ip netns exec priv ip route add default via 10.0.1.1
  sudo ip netns exec pub ip route add default via 10.0.2.1
  sudo ip netns exec r1 sysctl -w net.ipv4.ip_forward=1 > /dev/null

  echo "[+] Enabling NAT on router..."
  sudo ip netns exec r1 iptables -t nat -A POSTROUTING -o veth-r1-pub -j MASQUERADE

  echo "[+] VPC created successfully."
}

test_vpc() {
  echo "[+] Testing connectivity..."
  sudo ip netns exec priv ping -c 3 10.0.1.1
  sudo ip netns exec pub ping -c 3 10.0.2.1
  sudo ip netns exec priv ping -c 3 10.0.2.10
  echo "[+] All tests completed."
}

cleanup_vpc() {
  echo "[+] Cleaning up..."
  sudo ip netns delete priv 2>/dev/null
  sudo ip netns delete pub 2>/dev/null
  sudo ip netns delete r1 2>/dev/null
  sudo ip link delete veth-priv 2>/dev/null
  sudo ip link delete veth-pub 2>/dev/null
  echo "[+] Cleanup complete."
}

case "$ACTION" in
  create)
    create_vpc
    ;;
  test)
    test_vpc
    ;;
  cleanup)
    cleanup_vpc
    ;;
  *)
    echo "Usage: sudo bash vpcctl.sh {create|test|cleanup}"
    ;;
esac
