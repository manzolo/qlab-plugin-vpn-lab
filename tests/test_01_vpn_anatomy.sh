#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 1 — VPN Anatomy${RESET}"; echo ""

# 1.1 WireGuard installed on server
assert "wg installed on server" ssh_server "which wg"
assert "wg-quick installed on server" ssh_server "which wg-quick"

# 1.2 WireGuard installed on client
assert "wg installed on client" ssh_client "which wg"
assert "wg-quick installed on client" ssh_client "which wg-quick"

# 1.3 OpenVPN installed on server
assert "openvpn installed on server" ssh_server "which openvpn"

# 1.4 OpenVPN installed on client
assert "openvpn installed on client" ssh_client "which openvpn"

# 1.5 Internal LAN connectivity
ping_result=$(ssh_server "ping -c 1 -W 3 192.168.100.2 2>/dev/null" || echo "")
assert_contains "Server can ping client" "$ping_result" "1 received|1 packets received"

ping_result2=$(ssh_client "ping -c 1 -W 3 192.168.100.1 2>/dev/null" || echo "")
assert_contains "Client can ping server" "$ping_result2" "1 received|1 packets received"

# 1.6 tcpdump available
assert "tcpdump on server" ssh_server "which tcpdump"

report_results "Exercise 1"
