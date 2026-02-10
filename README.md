# vpn-lab — VPN Configuration Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://github.com/manzolo/qlab)

A [QLab](https://github.com/manzolo/qlab) plugin that boots two virtual machines for practicing VPN configuration with both WireGuard and OpenVPN.

## Architecture

```
┌─────────────────┐          ┌─────────────────┐
│  vpn-lab-server │          │  vpn-lab-client │
│  SSH: 2235      │◄────────►│  SSH: 2236      │
│  WG:  51820/udp │          │                 │
│  VPN: 1194/udp  │          │  WG/OpenVPN     │
│                 │          │  client tools   │
└─────────────────┘          └─────────────────┘
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
5. **QEMU boot**: Starts both VMs with SSH and VPN port forwarding

## Credentials

Both VMs use the same credentials:
- **Username:** `labuser`
- **Password:** `labpass`

## Ports

| VM              | Service   | Host Port | VM Port   |
|-----------------|-----------|-----------|-----------|
| vpn-lab-server  | SSH       | 2235      | 22        |
| vpn-lab-server  | WireGuard | 51820     | 51820/udp |
| vpn-lab-server  | OpenVPN   | 1194      | 1194/udp  |
| vpn-lab-client  | SSH       | 2236      | 22        |

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

1. **WireGuard setup**: Generate keys on both VMs with `wg genkey`, configure `/etc/wireguard/wg0.conf`, and bring up the tunnel
2. **Test WireGuard**: Ping through the VPN tunnel and verify encrypted traffic with `tcpdump`
3. **OpenVPN setup**: Configure the OpenVPN server with a static key, create a client config, and connect
4. **Traffic analysis**: Use `tcpdump -i any -n` on both VMs to see encrypted vs. unencrypted traffic
5. **VPN security**: Experiment with different cipher settings, key sizes, and access controls

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
