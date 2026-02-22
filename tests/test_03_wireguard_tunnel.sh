#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 3 — WireGuard Tunnel${RESET}"; echo ""

# Cleanup any previous state
cleanup_vpn

# 3.1 Generate keys
server_priv=$(ssh_server "wg genkey")
server_pub=$(echo "$server_priv" | ssh_server "wg pubkey")
client_priv=$(ssh_client "wg genkey")
client_pub=$(echo "$client_priv" | ssh_client "wg pubkey")

# 3.2 Configure server
ssh_server "sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
PrivateKey = ${server_priv}
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = ${client_pub}
AllowedIPs = 10.0.0.2/32
WGEOF'" >/dev/null 2>&1

# 3.3 Configure client
ssh_client "sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
PrivateKey = ${client_priv}
Address = 10.0.0.2/24

[Peer]
PublicKey = ${server_pub}
Endpoint = 192.168.100.1:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
WGEOF'" >/dev/null 2>&1

# 3.4 Start WireGuard on both sides
ssh_server "sudo wg-quick up wg0" >/dev/null 2>&1
ssh_client "sudo wg-quick up wg0" >/dev/null 2>&1

# 3.5 Verify tunnel interface
wg_status=$(ssh_server "sudo wg show wg0 2>/dev/null" || echo "")
assert_contains "WireGuard interface up on server" "$wg_status" "interface: wg0"

wg_client=$(ssh_client "sudo wg show wg0 2>/dev/null" || echo "")
assert_contains "WireGuard interface up on client" "$wg_client" "interface: wg0"

# 3.6 Ping through tunnel
sleep 2
tunnel_ping=$(ssh_client "ping -c 2 -W 3 10.0.0.1 2>/dev/null" || echo "")
assert_contains "Client can ping server through tunnel" "$tunnel_ping" "received|bytes from"

# Cleanup
cleanup_vpn

report_results "Exercise 3"
