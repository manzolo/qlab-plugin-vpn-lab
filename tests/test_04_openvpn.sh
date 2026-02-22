#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 4 — OpenVPN Installation${RESET}"; echo ""

# 4.1 OpenVPN installed on server
assert "openvpn on server" ssh_server "which openvpn"
openvpn_ver=$(ssh_server "openvpn --version 2>/dev/null | head -1" || echo "")
assert_contains "OpenVPN version available" "$openvpn_ver" "OpenVPN"

# 4.2 OpenVPN installed on client
assert "openvpn on client" ssh_client "which openvpn"

# 4.3 iptables available for NAT
assert "iptables on server" ssh_server "which iptables"

# 4.4 IP forwarding can be enabled
ssh_server "sudo sysctl -w net.ipv4.ip_forward=1" >/dev/null 2>&1
fwd=$(ssh_server "cat /proc/sys/net/ipv4/ip_forward 2>/dev/null")
assert_contains "IP forwarding enabled" "$fwd" "1"

# Reset forwarding
ssh_server "sudo sysctl -w net.ipv4.ip_forward=0" >/dev/null 2>&1

report_results "Exercise 4"
