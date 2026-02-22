#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 5 — Network Verification${RESET}"; echo ""

# 5.1 Server has internal IP
server_ip=$(ssh_server "ip addr show 2>/dev/null")
assert_contains "Server has 192.168.100.1" "$server_ip" "192.168.100.1"

# 5.2 Client has internal IP
client_ip=$(ssh_client "ip addr show 2>/dev/null")
assert_contains "Client has 192.168.100.2" "$client_ip" "192.168.100.2"

# 5.3 Bidirectional connectivity
ping_s2c=$(ssh_server "ping -c 1 -W 3 192.168.100.2 2>/dev/null" || echo "")
assert_contains "Server -> Client ping" "$ping_s2c" "1 received|1 packets received"

ping_c2s=$(ssh_client "ping -c 1 -W 3 192.168.100.1 2>/dev/null" || echo "")
assert_contains "Client -> Server ping" "$ping_c2s" "1 received|1 packets received"

# 5.4 Network tools available
assert "tcpdump on server" ssh_server "which tcpdump"
assert "ip command available" ssh_server "which ip"

report_results "Exercise 5"
