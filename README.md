# vpn-lab — WireGuard & OpenVPN Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Walkthrough](https://img.shields.io/badge/walkthrough-EN%20%26%20IT-informational)](docs/walkthrough-en.pdf)

A two-VM [QLab](https://github.com/manzolo/qlab) lab on a private LAN — a VPN server and a
client — for building a tunnel two ways (WireGuard and OpenVPN), then proving it works by
watching the traffic go from plaintext to ciphertext on the wire.

## Quick start

```bash
qlab install vpn-lab
qlab run vpn-lab             # boots 2 VMs (~90s)
qlab shell vpn-lab-server    # labuser / labpass
qlab shell vpn-lab-client    # labuser / labpass
qlab test vpn-lab            # run the automated checks
qlab stop vpn-lab
```

## What's inside

| # | Exercise | What you do |
|---|----------|-------------|
| 1 | WireGuard | key pairs, `wg0.conf` on both ends, a tunnel on `10.10.0.0/24` |
| 2 | OpenVPN (static key) | a shared secret, `server.conf` / `client.ovpn`, a tunnel on `10.20.0.0/24` |
| 3 | Traffic analysis | tcpdump: ciphertext on `eth0` vs plaintext inside `wg0` / `tun0` |
| 4 | Firewall rules | iptables to allow only VPN and SSH, then verify |

## Network

Private LAN `192.168.100.0/24`, isolated between the two VMs.

| VM | Address | Role |
|----|---------|------|
| `vpn-lab-server` | `192.168.100.1` | WireGuard / OpenVPN endpoint |
| `vpn-lab-client` | `192.168.100.2` | the other end |

SSH: `labuser` / `labpass`, dynamically forwarded — see `qlab ports`.

## Learn more

- 📖 **[Step-by-step guide](guide.md)** — every exercise with full configs
- 📄 **Illustrated walkthrough** — a real run, captured live: **[English](docs/walkthrough-en.pdf)** · **[Italiano](docs/walkthrough-it.pdf)**
- 🧩 **[QLab](https://github.com/manzolo/qlab)** — the plugin runner: how install, overlays and cloud-init work
