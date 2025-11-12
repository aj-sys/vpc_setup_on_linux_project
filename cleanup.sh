#!/bin/bash
# cleanup.sh - Safely remove VPC namespaces and links

echo "[+] Performing clean teardown..."
sudo ip netns delete priv 2>/dev/null
sudo ip netns delete pub 2>/dev/null
sudo ip netns delete r1 2>/dev/null
sudo ip link delete veth-priv 2>/dev/null
sudo ip link delete veth-pub 2>/dev/null
echo "[+] Cleanup done. Verify with:"
echo "ip netns list"
echo "ip link show"
