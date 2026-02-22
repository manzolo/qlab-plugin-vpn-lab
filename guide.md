# VPN Lab — Step-by-Step Guide

This guide walks you through configuring WireGuard and OpenVPN from scratch using the two lab VMs.

## Prerequisites

Start the lab and wait for both VMs to finish booting (~90 seconds):

```bash
qlab run vpn-lab
```

Open **two terminals** and connect to each VM:

```bash
# Terminal 1 — Server
qlab shell vpn-lab-server

# Terminal 2 — Client
qlab shell vpn-lab-client
```

On each VM, make sure cloud-init has finished:

```bash
cloud-init status --wait
```

## Network Topology

Each VM has **two network interfaces**:

- **eth0** (SLIRP): for SSH access from the host (`qlab shell`)
- **Internal LAN**: a direct virtual link between the VMs (`192.168.100.0/24`)

```
        Host Machine
       ┌────────────┐
       │  SSH :auto  │──────► vpn-lab-server
       │  SSH :auto  │──────► vpn-lab-client
       └────────────┘

   Internal LAN (192.168.100.0/24)
  ┌──────────────────────────────────┐
  │                                  │
  │  ┌─────────────┐   ┌─────────────┐
  │  │ vpn-server  │   │ vpn-client  │
  │  │ 192.168.    │   │ 192.168.    │
  │  │   100.1     │◄─►│   100.2     │
  │  │ SSH: dynamic│   │ SSH: dynamic│
  │  └─────────────┘   └─────────────┘
  └──────────────────────────────────┘
```

The VMs can reach each other directly on the internal LAN — no port forwarding needed. The VPN endpoints use `192.168.100.1` (server) as the target address.

The VPN tunnel creates a **separate private network** on top of the LAN:

- WireGuard tunnel: `10.10.0.0/24` (server `10.10.0.1`, client `10.10.0.2`)
- OpenVPN tunnel: `10.20.0.0/24` (server `10.20.0.1`, client `10.20.0.2`)

---

## Exercise 1: WireGuard VPN

### 1.1 Generate keys (on both VMs)

Run this on **both** server and client:

```bash
# Generate a private key and derive the public key
wg genkey | tee privatekey | wg pubkey > publickey

# Display both keys (you'll need them for the config files)
echo "Private key: $(cat privatekey)"
echo "Public key:  $(cat publickey)"
```

Take note of each VM's **public key** — you'll need to paste the server's public key into the client config and vice versa.

### 1.2 Configure the server

On **vpn-lab-server**, create the WireGuard config:

```bash
sudo nano /etc/wireguard/wg0.conf
```

Paste the following, replacing the placeholder values:

```ini
[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = <SERVER_PRIVATE_KEY>

[Peer]
PublicKey = <CLIENT_PUBLIC_KEY>
AllowedIPs = 10.10.0.2/32
```

Replace:
- `<SERVER_PRIVATE_KEY>` with the content of `privatekey` on the **server**
- `<CLIENT_PUBLIC_KEY>` with the content of `publickey` on the **client**

### 1.3 Configure the client

On **vpn-lab-client**, create the WireGuard config:

```bash
sudo nano /etc/wireguard/wg0.conf
```

```ini
[Interface]
Address = 10.10.0.2/24
PrivateKey = <CLIENT_PRIVATE_KEY>

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = 192.168.100.1:51820
AllowedIPs = 10.10.0.1/32
PersistentKeepalive = 25
```

Replace:
- `<CLIENT_PRIVATE_KEY>` with the content of `privatekey` on the **client**
- `<SERVER_PUBLIC_KEY>` with the content of `publickey` on the **server**

> **Why `192.168.100.1`?** That's the server's IP on the internal LAN that connects both VMs directly.

> **Why `PersistentKeepalive`?** It ensures the tunnel stays active by sending periodic packets.

### 1.4 Bring up the tunnel

On the **server** first, then the **client**:

```bash
# Server
sudo wg-quick up wg0

# Client
sudo wg-quick up wg0
```

### 1.5 Verify

```bash
# Check WireGuard status (on both VMs)
sudo wg show

# Ping from client to server through the tunnel
ping 10.10.0.1

# Ping from server to client through the tunnel
ping 10.10.0.2
```

A working `wg show` output looks like this:

```
interface: wg0
  public key: ...
  private key: (hidden)
  listening port: 51820

peer: ...
  endpoint: 192.168.100.1:51820
  allowed ips: 10.10.0.1/32
  latest handshake: 5 seconds ago    <-- this confirms the tunnel is up
  transfer: 348 B received, 436 B sent
```

### 1.6 Tear down

```bash
sudo wg-quick down wg0
```

---

## Exercise 2: OpenVPN (Static Key)

This exercise uses OpenVPN's **static key mode** — the simplest way to create a point-to-point tunnel. No certificates or PKI required.

### 2.1 Generate a static key (on server)

On **vpn-lab-server**:

```bash
sudo openvpn --genkey secret /etc/openvpn/static.key
```

Display the key so you can copy it to the client:

```bash
sudo cat /etc/openvpn/static.key
```

### 2.2 Copy the key to the client

On **vpn-lab-client**, create the same key file:

```bash
sudo nano /etc/openvpn/static.key
```

Paste the entire content of the key (including the `-----BEGIN...` and `-----END...` lines).

> **Tip:** In a real scenario you would use `scp` to transfer the key securely. In this lab, copy-paste between terminals works fine.

### 2.3 Configure the server

On **vpn-lab-server**:

```bash
sudo nano /etc/openvpn/server.conf
```

```
dev tun
ifconfig 10.20.0.1 10.20.0.2
secret /etc/openvpn/static.key
port 1194
proto udp
keepalive 10 60
persist-tun
persist-key
verb 3
```

### 2.4 Configure the client

On **vpn-lab-client**:

```bash
sudo nano /etc/openvpn/client.ovpn
```

```
dev tun
remote 192.168.100.1 1194 udp
ifconfig 10.20.0.2 10.20.0.1
secret /etc/openvpn/static.key
persist-tun
persist-key
verb 3
```

> **Note:** `remote 192.168.100.1 1194` tells the client to connect to the server's IP on the internal LAN.

### 2.5 Start the tunnel

Start the **server first** (in foreground to see logs):

```bash
# Server
sudo openvpn --config /etc/openvpn/server.conf
```

Then in another session or terminal on the **client**:

```bash
# Client
sudo openvpn --config /etc/openvpn/client.ovpn
```

You should see `Initialization Sequence Completed` on both sides.

> **Tip:** To run OpenVPN in the background, add `--daemon` to the command, or press `Ctrl+Z` then `bg` after verifying it connects.

### 2.6 Verify

From a separate shell on the client (open a second SSH session with `qlab shell vpn-lab-client`):

```bash
# Ping the server through the OpenVPN tunnel
ping 10.20.0.1
```

---

## Exercise 3: Traffic Analysis with tcpdump

This exercise shows you the difference between encrypted VPN traffic and plaintext traffic.

### 3.1 Capture traffic on the server

On **vpn-lab-server**, start a capture on all interfaces:

```bash
sudo tcpdump -i any -n -v
```

### 3.2 Observe encrypted vs. plaintext

With the WireGuard or OpenVPN tunnel up, run this from the **client**:

```bash
# Traffic through the VPN tunnel (encrypted)
ping 10.10.0.1    # WireGuard
# or
ping 10.20.0.1    # OpenVPN
```

In the tcpdump output on the server you'll see:
- On `eth0`: **encrypted UDP packets** (WireGuard on port 51820, or OpenVPN on port 1194)
- On `wg0` or `tun0`: **plaintext ICMP** ping packets

### 3.3 Filter specific traffic

```bash
# Only WireGuard traffic
sudo tcpdump -i eth0 udp port 51820 -n

# Only OpenVPN traffic
sudo tcpdump -i eth0 udp port 1194 -n

# Only tunnel interface traffic (plaintext inside the VPN)
sudo tcpdump -i wg0 -n       # WireGuard
sudo tcpdump -i tun0 -n      # OpenVPN
```

---

## Exercise 4: Firewall Rules

Practice configuring iptables to control VPN traffic.

### 4.1 View current rules

```bash
sudo iptables -L -n -v
```

By default there are no rules (everything is allowed).

### 4.2 Example: allow only VPN traffic

```bash
# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (so you don't lock yourself out!)
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow WireGuard
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT

# Allow OpenVPN
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# Drop everything else
sudo iptables -A INPUT -j DROP
```

### 4.3 Reset rules

```bash
sudo iptables -F
```

---

## Troubleshooting

### WireGuard: "Unable to access interface: No such device"

The `wg0` interface hasn't been created yet. Run `sudo wg-quick up wg0` first.

### WireGuard: handshake not completing

- Verify the **public keys** are correct (server's pubkey in client config, and vice versa)
- Check that the server's `ListenPort` matches the client's `Endpoint` port
- Make sure you started the server **before** the client
- Verify the internal LAN works: `ping 192.168.100.1` from the client (without VPN)

### OpenVPN: "Error opening configuration file"

Use the full path: `sudo openvpn --config /etc/openvpn/server.conf`

### OpenVPN: connection timeout

- Make sure the server is running first
- Verify the static key is **identical** on both VMs
- Check the `remote` address in the client config is `192.168.100.1`
- Verify the internal LAN works: `ping 192.168.100.1` from the client

### Can't ping through the tunnel

- Check that both sides show the tunnel interface is up: `ip addr show wg0` (or `tun0`)
- Verify `AllowedIPs` includes the peer's tunnel IP
- Try `sudo wg show` to check if there's a handshake

### General: packages not installed

If commands like `wg` or `openvpn` are not found, cloud-init may still be running:

```bash
cloud-init status --wait
```
