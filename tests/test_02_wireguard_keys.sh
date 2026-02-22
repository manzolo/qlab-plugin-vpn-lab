#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 2 — WireGuard Key Generation${RESET}"; echo ""

# 2.1 Generate server key pair
ssh_server "wg genkey | tee /tmp/server_private | wg pubkey > /tmp/server_public" >/dev/null 2>&1
server_priv=$(ssh_server "cat /tmp/server_private 2>/dev/null")
server_pub=$(ssh_server "cat /tmp/server_public 2>/dev/null")
assert_contains "Server private key generated" "$server_priv" "^[A-Za-z0-9+/=]"
assert_contains "Server public key generated" "$server_pub" "^[A-Za-z0-9+/=]"

# 2.2 Generate client key pair
ssh_client "wg genkey | tee /tmp/client_private | wg pubkey > /tmp/client_public" >/dev/null 2>&1
client_priv=$(ssh_client "cat /tmp/client_private 2>/dev/null")
client_pub=$(ssh_client "cat /tmp/client_public 2>/dev/null")
assert_contains "Client private key generated" "$client_priv" "^[A-Za-z0-9+/=]"
assert_contains "Client public key generated" "$client_pub" "^[A-Za-z0-9+/=]"

# 2.3 Keys are base64 encoded (44 chars)
server_key_len=${#server_pub}
assert_contains "Server key has correct length" "$server_key_len" "^4[34]$"

# Cleanup temp keys
ssh_server "rm -f /tmp/server_private /tmp/server_public" >/dev/null 2>&1
ssh_client "rm -f /tmp/client_private /tmp/client_public" >/dev/null 2>&1

report_results "Exercise 2"
