# vpn-lab — VPN Configuration Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://github.com/manzolo/qlab)

A [QLab](https://github.com/manzolo/qlab) plugin that boots two virtual machines for practicing VPN configuration with both WireGuard and OpenVPN.

## Architecture

```
    Internal LAN (192.168.100.0/24)
┌─────────────────────────────────────┐
│                                     │
│  ┌─────────────────┐  ┌─────────────────┐
│  │  vpn-lab-server │  │  vpn-lab-client │
│  │  SSH: 2240      │  │  SSH: 2241      │
│  │  192.168.100.1  │◄►│  192.168.100.2  │
│  │  WG / OpenVPN   │  │  WG / OpenVPN   │
│  └─────────────────┘  └─────────────────┘
│                                     │
└─────────────────────────────────────┘
```

## Objectives

- Configure a WireGuard VPN tunnel between server and client
- Configure an OpenVPN server and connect a client
- Test VPN connectivity and traffic encryption
- Monitor VPN traffic with tcpdump
- Understand VPN security best practices

## How It Works

1. **Cloud image**: Downloads a minimal Ubuntu 22.04 cloud image (~250MB)
2. **Cloud-init**: Creates `user-data` for both VMs with VPN packages
3. **ISO generation**: Packs cloud-init files into ISOs (cidata)
4. **Overlay disks**: Creates COW disks for each VM (original stays untouched)
5. **QEMU boot**: Starts both VMs with SSH access and a shared internal LAN

## Credentials

Both VMs use the same credentials:
- **Username:** `labuser`
- **Password:** `labpass`

## Network

| VM              | SSH (host) | Internal LAN IP  |
|-----------------|------------|------------------|
| vpn-lab-server  | port 2240  | 192.168.100.1    |
| vpn-lab-client  | port 2241  | 192.168.100.2    |

The VMs are connected by a direct internal LAN (`192.168.100.0/24`) via QEMU socket networking. VPN traffic (WireGuard, OpenVPN) flows over this LAN.

## Usage

```bash
# Install the plugin
qlab install vpn-lab

# Run the lab (starts both VMs)
qlab run vpn-lab

# Wait ~90s for boot and package installation, then:

# Connect to the server VM
qlab shell vpn-lab-server

# Connect to the client VM
qlab shell vpn-lab-client

# Stop both VMs
qlab stop vpn-lab

# Stop a single VM
qlab stop vpn-lab-server
qlab stop vpn-lab-client
```

## Exercises

> **New to VPNs?** See the [Step-by-Step Guide](GUIDE.md) for complete walkthroughs with full config examples.

| # | Exercise | What you'll do |
|---|----------|----------------|
| 1 | **WireGuard VPN** | Generate key pairs, write `wg0.conf` on both VMs, bring up a tunnel on `10.10.0.0/24` |
| 2 | **OpenVPN (static key)** | Generate a shared secret, write `server.conf` / `client.ovpn`, establish a tunnel on `10.20.0.0/24` |
| 3 | **Traffic analysis** | Use `tcpdump` to compare encrypted traffic on `eth0` vs. plaintext on `wg0`/`tun0` |
| 4 | **Firewall rules** | Configure `iptables` to allow only VPN and SSH traffic, then verify |

## Managing VMs

```bash
# View boot logs
qlab log vpn-lab-server
qlab log vpn-lab-client

# Check running VMs
qlab status
```

## Resetting

To start fresh, stop and re-run:

```bash
qlab stop vpn-lab
qlab run vpn-lab
```

Or reset the entire workspace:

```bash
qlab reset
```
