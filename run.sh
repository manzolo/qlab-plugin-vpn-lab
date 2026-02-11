#!/usr/bin/env bash
# vpn-lab run script — boots two VMs for VPN configuration labs

set -euo pipefail

PLUGIN_NAME="vpn-lab"
SERVER_VM="vpn-lab-server"
CLIENT_VM="vpn-lab-client"
SERVER_SSH_PORT=2235
CLIENT_SSH_PORT=2236
VPN_PORT=1194
WG_PORT=51820

echo "============================================="
echo "  vpn-lab: VPN Configuration Lab"
echo "============================================="
echo ""
echo "  This lab creates two VMs:"
echo ""
echo "    1. $SERVER_VM  (SSH port $SERVER_SSH_PORT)"
echo "       Runs VPN server (WireGuard or OpenVPN)"
echo "       Practice VPN configuration and security"
echo ""
echo "    2. $CLIENT_VM  (SSH port $CLIENT_SSH_PORT)"
echo "       Equipped with VPN client tools"
echo "       Connect to the VPN server and test connectivity"
echo ""
echo "  VPN Configuration:"
echo "    - VPN Server: $SERVER_VM"
echo "    - VPN Client: $CLIENT_VM"
echo "    - VPN Port: $VPN_PORT (OpenVPN) or $WG_PORT (WireGuard)"
echo ""

# Source QLab core libraries
if [[ -z "${QLAB_ROOT:-}" ]]; then
    echo "ERROR: QLAB_ROOT not set. Run this plugin via 'qlab run ${PLUGIN_NAME}'."
    exit 1
fi

for lib_file in "$QLAB_ROOT"/lib/*.bash; do
    # shellcheck source=/dev/null
    [[ -f "$lib_file" ]] && source "$lib_file"
done

# Configuration
WORKSPACE_DIR="${WORKSPACE_DIR:-.qlab}"
LAB_DIR="lab"
IMAGE_DIR="$WORKSPACE_DIR/images"
CLOUD_IMAGE_URL=$(get_config CLOUD_IMAGE_URL "https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img")
CLOUD_IMAGE_FILE="$IMAGE_DIR/ubuntu-22.04-minimal-cloudimg-amd64.img"
MEMORY="${QLAB_MEMORY:-$(get_config DEFAULT_MEMORY 1024)}"

# Ensure directories exist
mkdir -p "$LAB_DIR" "$IMAGE_DIR"

# =============================================
# Step 1: Download cloud image (shared by both VMs)
# =============================================
info "Step 1: Cloud image"
if [[ -f "$CLOUD_IMAGE_FILE" ]]; then
    success "Cloud image already downloaded: $CLOUD_IMAGE_FILE"
else
    echo ""
    echo "  Cloud images are pre-built OS images designed for cloud environments."
    echo "  Both VMs will share the same base image via overlay disks."
    echo ""
    info "Downloading Ubuntu cloud image..."
    echo "  URL: $CLOUD_IMAGE_URL"
    echo "  This may take a few minutes depending on your connection."
    echo ""
    check_dependency curl || exit 1
    curl -L -o "$CLOUD_IMAGE_FILE" "$CLOUD_IMAGE_URL" || {
        error "Failed to download cloud image."
        echo "  Check your internet connection and try again."
        exit 1
    }
    success "Cloud image downloaded: $CLOUD_IMAGE_FILE"
fi
echo ""

# =============================================
# Step 2: Cloud-init configurations
# =============================================
info "Step 2: Cloud-init configuration for both VMs"
echo ""

# --- VPN Server VM cloud-init ---
info "Creating cloud-init for $SERVER_VM..."
cat > "$LAB_DIR/user-data-server" <<'USERDATA'
#cloud-config
hostname: vpn-lab-server
package_update: true
users:
  - name: labuser
    plain_text_passwd: labpass
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - "__QLAB_SSH_PUB_KEY__"
ssh_pwauth: true
packages:
  - wireguard
  - wireguard-tools
  - openvpn
  - iptables
  - net-tools
  - iputils-ping
  - tcpdump
write_files:
  - path: /etc/profile.d/cloud-init-status.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      if command -v cloud-init >/dev/null 2>&1; then
        status=$(cloud-init status 2>/dev/null)
        if echo "$status" | grep -q "running"; then
          printf '\033[1;33m'
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "  Cloud-init is still running..."
          echo "  Some packages and services may not be ready yet."
          echo "  Run 'cloud-init status --wait' to wait for completion."
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          printf '\033[0m\n'
        fi
      fi
  - path: /etc/motd.raw
    content: |
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m
        \033[1;32mvpn-lab-server\033[0m — \033[1mVPN Server Lab\033[0m
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m

        \033[1;33mRole:\033[0m  VPN Server VM

        \033[1;33mInstalled tools:\033[0m
          \033[0;32mWireGuard\033[0m      (port 51820/udp)
          \033[0;32mOpenVPN\033[0m        (port 1194/udp)

        \033[1;33mWireGuard Commands:\033[0m
          \033[0;32msudo wg show\033[0m                    show WireGuard status
          \033[0;32msudo wg showconf wg0\033[0m           show WireGuard config
          \033[0;32msudo wg genkey | tee privatekey | wg pubkey > publickey\033[0m

        \033[1;33mOpenVPN Commands:\033[0m
          \033[0;32msudo systemctl status openvpn\033[0m   show OpenVPN status
          \033[0;32msudo openvpn --config server.conf\033[0m  start OpenVPN server

        \033[1;33mNetwork:\033[0m
          \033[0;32msudo iptables -L -n -v\033[0m        list firewall rules
          \033[0;32msudo tcpdump -i any -n\033[0m         capture all traffic

        \033[1;33mCredentials:\033[0m  \033[1;36mlabuser\033[0m / \033[1;36mlabpass\033[0m
        \033[1;33mExit:\033[0m         type '\033[1;31mexit\033[0m'

      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m


runcmd:
  - chmod -x /etc/update-motd.d/*
  - sed -i 's/^#\?PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config
  - sed -i 's/^session.*pam_motd.*/# &/' /etc/pam.d/sshd
  - printf '%b\n' "$(cat /etc/motd.raw)" > /etc/motd
  - rm -f /etc/motd.raw
  - systemctl restart sshd
  - echo "=== vpn-lab-server VM is ready! ==="
USERDATA

# Inject the SSH public key into user-data
sed -i "s|__QLAB_SSH_PUB_KEY__|${QLAB_SSH_PUB_KEY:-}|g" "$LAB_DIR/user-data-server"

cat > "$LAB_DIR/meta-data-server" <<METADATA
instance-id: ${SERVER_VM}-001
local-hostname: ${SERVER_VM}
METADATA

success "Created cloud-init for $SERVER_VM"

# --- VPN Client VM cloud-init ---
info "Creating cloud-init for $CLIENT_VM..."
cat > "$LAB_DIR/user-data-client" <<'USERDATA'
#cloud-config
hostname: vpn-lab-client
package_update: true
users:
  - name: labuser
    plain_text_passwd: labpass
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - "__QLAB_SSH_PUB_KEY__"
ssh_pwauth: true
packages:
  - wireguard
  - wireguard-tools
  - openvpn
  - net-tools
  - iputils-ping
  - curl
  - tcpdump
write_files:
  - path: /etc/profile.d/cloud-init-status.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      if command -v cloud-init >/dev/null 2>&1; then
        status=$(cloud-init status 2>/dev/null)
        if echo "$status" | grep -q "running"; then
          printf '\033[1;33m'
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "  Cloud-init is still running..."
          echo "  Some packages and services may not be ready yet."
          echo "  Run 'cloud-init status --wait' to wait for completion."
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          printf '\033[0m\n'
        fi
      fi
  - path: /etc/motd.raw
    content: |
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m
        \033[1;31mvpn-lab-client\033[0m — \033[1mVPN Client Lab\033[0m
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m

        \033[1;33mRole:\033[0m  VPN Client VM

        \033[1;33mTarget server (via QEMU gateway):\033[0m
          \033[0;32m10.0.2.2:51820\033[0m   WireGuard server
          \033[0;32m10.0.2.2:1194\033[0m    OpenVPN server

        \033[1;33mWireGuard:\033[0m
          \033[0;32msudo wg-quick up wg0\033[0m                  connect
          \033[0;32msudo wg-quick down wg0\033[0m                disconnect
          \033[0;32msudo wg show\033[0m                          status

        \033[1;33mOpenVPN:\033[0m
          \033[0;32msudo openvpn --config client.ovpn\033[0m     connect
          \033[0;32msudo systemctl status openvpn\033[0m          status

        \033[1;33mNetwork:\033[0m
          \033[0;32msudo ping 10.0.2.2\033[0m               test connectivity
          \033[0;32msudo tcpdump -i any -n\033[0m            capture traffic

        \033[1;33mCredentials:\033[0m  \033[1;36mlabuser\033[0m / \033[1;36mlabpass\033[0m
        \033[1;33mExit:\033[0m         type '\033[1;31mexit\033[0m'

      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m


runcmd:
  - chmod -x /etc/update-motd.d/*
  - sed -i 's/^#\?PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config
  - sed -i 's/^session.*pam_motd.*/# &/' /etc/pam.d/sshd
  - printf '%b\n' "$(cat /etc/motd.raw)" > /etc/motd
  - rm -f /etc/motd.raw
  - systemctl restart sshd
  - echo "=== vpn-lab-client VM is ready! ==="
USERDATA

# Inject the SSH public key into user-data
sed -i "s|__QLAB_SSH_PUB_KEY__|${QLAB_SSH_PUB_KEY:-}|g" "$LAB_DIR/user-data-client"

cat > "$LAB_DIR/meta-data-client" <<METADATA
instance-id: ${CLIENT_VM}-001
local-hostname: ${CLIENT_VM}
METADATA

success "Created cloud-init for $CLIENT_VM"
echo ""

# =============================================
# Step 3: Generate cloud-init ISOs
# =============================================
info "Step 3: Cloud-init ISOs"
echo ""
check_dependency genisoimage || {
    warn "genisoimage not found. Install it with: sudo apt install genisoimage"
    exit 1
}

CIDATA_SERVER="$LAB_DIR/cidata-server.iso"
genisoimage -output "$CIDATA_SERVER" -volid cidata -joliet -rock \
    -graft-points "user-data=$LAB_DIR/user-data-server" "meta-data=$LAB_DIR/meta-data-server" 2>/dev/null
success "Created cloud-init ISO: $CIDATA_SERVER"

CIDATA_CLIENT="$LAB_DIR/cidata-client.iso"
genisoimage -output "$CIDATA_CLIENT" -volid cidata -joliet -rock \
    -graft-points "user-data=$LAB_DIR/user-data-client" "meta-data=$LAB_DIR/meta-data-client" 2>/dev/null
success "Created cloud-init ISO: $CIDATA_CLIENT"
echo ""

# =============================================
# Step 4: Create overlay disks
# =============================================
info "Step 4: Overlay disks"
echo ""
echo "  Each VM gets its own overlay disk (copy-on-write) so the"
echo "  base cloud image is never modified."
echo ""

OVERLAY_SERVER="$LAB_DIR/${SERVER_VM}-disk.qcow2"
if [[ -f "$OVERLAY_SERVER" ]]; then rm -f "$OVERLAY_SERVER"; fi
create_overlay "$CLOUD_IMAGE_FILE" "$OVERLAY_SERVER" "${QLAB_DISK_SIZE:-}"

OVERLAY_CLIENT="$LAB_DIR/${CLIENT_VM}-disk.qcow2"
if [[ -f "$OVERLAY_CLIENT" ]]; then rm -f "$OVERLAY_CLIENT"; fi
create_overlay "$CLOUD_IMAGE_FILE" "$OVERLAY_CLIENT" "${QLAB_DISK_SIZE:-}"
echo ""

# =============================================
# Step 5: Start both VMs
# =============================================
info "Step 5: Starting VMs"
echo ""

info "Starting $SERVER_VM (SSH port $SERVER_SSH_PORT)..."
start_vm "$OVERLAY_SERVER" "$CIDATA_SERVER" "$MEMORY" "$SERVER_VM" "$SERVER_SSH_PORT" \
    "hostfwd=udp::${WG_PORT}-:${WG_PORT}" \
    "hostfwd=udp::${VPN_PORT}-:${VPN_PORT}"

echo ""

info "Starting $CLIENT_VM (SSH port $CLIENT_SSH_PORT)..."
start_vm "$OVERLAY_CLIENT" "$CIDATA_CLIENT" "$MEMORY" "$CLIENT_VM" "$CLIENT_SSH_PORT"

echo ""
echo "============================================="
echo "  vpn-lab: Both VMs are booting"
echo "============================================="
echo ""
echo "  VPN Server VM:"
echo "    SSH:   qlab shell $SERVER_VM"
echo "    Log:   qlab log $SERVER_VM"
echo "    Port:  $SERVER_SSH_PORT"
echo ""
echo "  VPN Client VM:"
echo "    SSH:   qlab shell $CLIENT_VM"
echo "    Log:   qlab log $CLIENT_VM"
echo "    Port:  $CLIENT_SSH_PORT"
echo ""
echo "  Credentials (both VMs):"
echo "    Username: labuser"
echo "    Password: labpass"
echo ""
echo "  Wait ~90s for boot + package installation."
echo ""
echo "  Stop both VMs:"
echo "    qlab stop $PLUGIN_NAME"
echo ""
echo "  Stop a single VM:"
echo "    qlab stop $SERVER_VM"
echo "    qlab stop $CLIENT_VM"
echo ""
echo "  Tip: override resources with environment variables:"
echo "    QLAB_MEMORY=4096 QLAB_DISK_SIZE=30G qlab run ${PLUGIN_NAME}"
echo "============================================="
