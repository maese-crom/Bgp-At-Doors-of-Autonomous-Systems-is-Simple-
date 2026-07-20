# Bgp-At-Doors-of-Autonomous-Systems-is-Simple- (a.k.a. badass)

A set of GNS3 network labs exploring BGP, OSPF and EVPN-VXLAN overlays using [FRRouting](https://frrouting.org/) containers. Each lab is a self-contained `.gns3project` topology plus the shell/`vtysh` scripts applied on every node, progressing from a single router bring-up to a full BGP EVPN spine-leaf fabric.

Every lab includes its own `README.md` fully documenting it.

## Summary

### [P1 — FRR router bring-up](./P1)
Introductory lab: a single FRR router (with `zebra`, `bgpd`, `ospfd` and `isisd` daemons enabled) connected to one Alpine host. No routing protocol is configured yet — the goal is to get comfortable with the Docker images, GNS3 topology and the FRR/`vtysh` console before touching any protocol.

### [P2 — Manual VXLAN L2 tunnel](./P2)
Two routers, each attached to its own host and to a shared switch, are bridged over a VXLAN tunnel built by hand with `ip link`/`brctl` commands — no control plane involved. Two flavors are provided per router: a **multicast** (`_g`) flood-and-learn VTEP and a **static unicast** (`_s`) point-to-point VTEP, to compare both VXLAN discovery methods.

### [P3 — BGP EVPN-VXLAN fabric](./P3)
A 4-router spine-leaf fabric: `router-1` is the spine and iBGP route-reflector, `router-2/3/4` are leafs each attached to a host. Underlay reachability is OSPF (loopback-to-loopback, point-to-point interfaces); the overlay is a single-AS iBGP session per leaf with the `l2vpn evpn` address-family, replacing P2's manual VXLAN with BGP-driven VTEP/MAC discovery (`advertise-all-vni`) — the actual "doors" a VXLAN overlay opens once BGP takes over the control plane.

-----------------------------------------------
-----------------------------------------------

## Stack

- **[GNS3](https://www.gns3.com/)**: network topology emulator, one `.gns3project` per lab.
- **[FRRouting](https://frrouting.org/)** (Docker image `frrouting/frr`): open-source routing stack providing the `zebra`, `bgpd` and `ospfd` daemons, driven through its `vtysh` CLI.
- **Alpine Linux** (Docker image `alpine`): lightweight hosts used as traffic endpoints on each network segment.
- **VXLAN / EVPN**: Ethernet-over-UDP overlay encapsulation, first built manually with `iproute2`/`bridge-utils` (P2), then automated through BGP's `l2vpn evpn` address-family (P3).

## Skills learnt

1. **FRRouting / Linux networking**: deploying an FRR container, enabling daemons, configuring interfaces, loopbacks and OSPF/BGP through `vtysh`.
2. **VXLAN overlays**: building a Layer-2 tunnel over a Layer-3 underlay by hand, comparing multicast flood-and-learn vs. static unicast VTEPs ([P2](./P2)).
3. **BGP EVPN**: using BGP as the control plane for VXLAN (spine route-reflector, iBGP peer groups, `advertise-all-vni`) instead of manual tunnel provisioning ([P3](./P3)).
4. **Network topology design**: modeling spine-leaf fabrics and point-to-point underlays in GNS3, and containerized network nodes with Docker.
