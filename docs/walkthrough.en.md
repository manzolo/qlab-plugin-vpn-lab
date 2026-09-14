---
kicker: QLab · vpn-lab
title: |
  A tunnel built
  from two keys
subtitle: >
  WireGuard configured from nothing on two machines, brought up, pinged through,
  and then watched on the wire — where the ICMP has disappeared and only UDP
  remains. Captured from a running pair.
facts:
  - [Command, "`qlab run vpn-lab`"]
  - [VMs, "`vpn-lab-server` 192.168.100.1 · `vpn-lab-client` 192.168.100.2"]
  - [Tunnel, "10.10.0.1 ↔ 10.10.0.2, UDP 51820"]
  - [Outcome, "`qlab test vpn-lab` → 5 exercises, 28 checks, all passed"]
---

## 1. Two machines, and nothing configured

{{evidence:topology}}

{{evidence:before as=shell}}

The lab ships the tools and no configuration at all. That is deliberate: the
exercise is the configuring, and there is very little of it. Everything in the
next section was done from this starting point.

## 2. Keys first, and only the public halves travel

{{evidence:build-tunnel as=shell}}

This is the whole of WireGuard's identity model. Each machine generates a
keypair and **keeps the private half**; what gets exchanged is the public key,
which is safe to print in a document like this one.

There are no certificates, no certificate authority, no handshake negotiation
about who you are. A peer is a public key with a list of addresses it is allowed
to use, and the config file is short enough to read in full.

Three fields carry the meaning:

- **`Address`** — the machine's address *inside* the tunnel. It has nothing to do
  with the LAN addresses in section 1.
- **`Endpoint`** — where to send the encrypted UDP. Only the client needs one:
  the server learns the client's endpoint from the first packet that arrives,
  which is why WireGuard copes with clients that move networks.
- **`AllowedIPs`** — a double-duty field, and the one that confuses people. On
  outgoing traffic it is a *route*: send these addresses to this peer. On
  incoming traffic it is an *access check*: a packet decrypted from this peer
  claiming a source outside its AllowedIPs is dropped. Routing and authorisation
  in one line.

`wg-quick up` then does by hand what you would otherwise type: create the
interface, load the config, add the address, set an MTU of 1420 — 1500 minus the
encapsulation overhead.

## 3. The tunnel, up

{{evidence:tunnel-up as=shell}}

Three packets, no loss, under a millisecond. And `wg show` reports what matters:
a **latest handshake** a few seconds ago, and a byte count in both directions.

Note the endpoint the server recorded: `192.168.100.2:36396`. The client never
declared a port — the server learned it from the packets that arrived. There is
also no "connected" state to report, because WireGuard has no connection: it is
UDP, it is stateless between handshakes, and `latest handshake` is the closest
thing to a session.

## 4. What the network sees

{{evidence:on-the-wire as=shell}}

The capture filter asked for `udp port 51820 or icmp`, on the interface the ping
actually crosses. Every single line is UDP, all the same length. **No ICMP
appears at all** — not because it was filtered out, but because on this wire it
does not exist. The pings are inside the encrypted payload.

That is the thing worth seeing rather than being told: an observer on the LAN
learns that two addresses are exchanging UDP on a known port, and how much, and
when. It learns nothing about what — not the protocol, not the inner addresses,
not the content.

{{evidence:teardown as=shell}}

## 5. And OpenVPN, for contrast

The lab installs OpenVPN alongside, and exercise 2 sets it up with a static key.
The comparison is the point of having both: OpenVPN runs over TLS with
negotiable ciphers, needs a certificate authority for anything beyond a shared
static key, and its configuration runs to dozens of lines. WireGuard has one
cipher suite and no negotiation, which is why there is nothing to choose and
nothing to get wrong — and also why it cannot be adapted when that suite ages.

## 6. Verification

{{evidence:qlab-test grep="Exercise [0-9]+:|Exercises |All exercises" as=shell}}

## 7. What to take away

- A peer is a public key. Private keys never leave the machine that made them.
- `Address` is inside the tunnel; `Endpoint` is outside it. Keeping the two
  straight solves most of the confusion.
- `AllowedIPs` is both the route out and the filter in.
- The server does not need to know where the client is; it learns the endpoint
  from the traffic.
- There is no connection. `latest handshake` is how you tell a tunnel is alive.
- On the wire there is only UDP. What travels inside is not visible from outside.

`guide.md` in the plugin carries the exercises: WireGuard by hand, OpenVPN with a
static key, traffic analysis with tcpdump, and the firewall rules around them.
