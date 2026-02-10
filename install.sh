#!/usr/bin/env bash
# vpn-lab install script

set -euo pipefail

echo ""
echo "  [vpn-lab] Installing..."
echo ""
echo "  This plugin creates two VMs for practicing VPN configuration:"
echo ""
echo "    1. vpn-lab-server  — VPN Server VM"
echo "       Runs WireGuard and OpenVPN server"
echo "       Practice VPN configuration and security"
echo ""
echo "    2. vpn-lab-client  — VPN Client VM"
echo "       Equipped with VPN client tools"
echo "       Connect to the VPN server and test connectivity"
echo ""
echo "  What you will learn:"
echo "    - How to configure a WireGuard VPN tunnel"
echo "    - How to configure an OpenVPN server and client"
echo "    - How to test VPN connectivity between VMs"
echo "    - How to monitor VPN traffic with tcpdump"
echo "    - How to secure VPN configurations"
echo ""

# Create lab working directory
mkdir -p lab

# Check for required tools
echo "  Checking dependencies..."
local_ok=true
for cmd in qemu-system-x86_64 qemu-img genisoimage curl; do
    if command -v "$cmd" &>/dev/null; then
        echo "    [OK] $cmd"
    else
        echo "    [!!] $cmd — not found (install before running)"
        local_ok=false
    fi
done

if [[ "$local_ok" == true ]]; then
    echo ""
    echo "  All dependencies are available."
else
    echo ""
    echo "  Some dependencies are missing. Install them with:"
    echo "    sudo apt install qemu-kvm qemu-utils genisoimage curl"
fi

echo ""
echo "  [vpn-lab] Installation complete."
echo "  Run with: qlab run vpn-lab"
