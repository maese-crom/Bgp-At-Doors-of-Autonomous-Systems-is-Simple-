# P3 — BGP EVPN-VXLAN fabric

### Description

The goal of this lab is to replace [P2](../P2)'s manual VXLAN tunnel with a proper **BGP EVPN** control plane over a small spine-leaf fabric. Knowledge acquired through it is:
- Building an OSPF underlay (point-to-point links, loopback-based router-IDs) to give every router IP reachability to every other loopback.
- Using a **BGP route reflector** with a dynamic peer-group (`bgp listen range`) so leafs can peer with the spine without being individually configured on it.
- Enabling the `l2vpn evpn` address-family to let BGP itself discover remote VTEPs and advertise MAC/VNI reachability (`advertise-all-vni`), instead of the manual multicast/unicast VXLAN setup from P2.

All routers reuse the FRR image built in [P1](../P1).

### Topology

```
                                    host-1 (30.1.1.1/24)
                                            |
                                         router-2 (leaf, 1.1.1.2)
                                            |
host-3 (30.1.1.3/24) -- router-4 (leaf, 1.1.1.4) -- router-1 (spine/RR, 1.1.1.1) -- router-3 (leaf, 1.1.1.3) -- host-2 (30.1.1.2/24)
```

- **`router-prando-a-1`** (spine): OSPF area 0 on `eth1`/`eth2`/`eth3` (point-to-point) plus loopback `1.1.1.1/32`; iBGP (AS 1) route reflector using a dynamic `ibgp` peer-group listening on `1.1.1.0/24`, with `l2vpn evpn` activated and `route-reflector-client` set. No host is attached to the spine.
- **`router-prando-a-2/3/4`** (leafs): each has one underlay link to the spine (`10.1.1.0/30`-style /30s) and one access port (`eth0`) bridged (`br0`) together with a `vxlan10` VTEP sourced from its own loopback. Each leaf peers with the spine (`neighbor 1.1.1.1 remote-as 1`), activates `l2vpn evpn` and runs `advertise-all-vni` so its local VNI 10 is advertised through BGP.
- **`host-prando-a-1/2/3`**: Alpine hosts, one per leaf, each on the `30.1.1.0/24` access subnet — this is the same broadcast domain stitched together purely through the EVPN overlay.

| Node | Role | Loopback | Underlay link to spine |
|---|---|---|---|
| router-1 | Spine / RR | 1.1.1.1/32 | eth1 → router-2 (10.1.1.1/30), eth2 → router-3 (10.1.1.5/30), eth3 → router-4 (10.1.1.9/30) |
| router-2 | Leaf | 1.1.1.2/32 | eth1, 10.1.1.2/30 |
| router-3 | Leaf | 1.1.1.3/32 | eth2, 10.1.1.6/30 |
| router-4 | Leaf | 1.1.1.4/32 | eth3, 10.1.1.10/30 |

### Files

- [`P3.gns3project`](./P3.gns3project): the GNS3 topology.
- [`_prando-a-1`](./_prando-a-1): spine router config — underlay interfaces, loopback, OSPF, and the iBGP route-reflector with dynamic peer-group.
- [`_prando-a-2`](./_prando-a-2), [`_prando-a-3`](./_prando-a-3), [`_prando-a-4`](./_prando-a-4): leaf router configs — bridge + VXLAN VTEP setup, underlay interface, loopback, OSPF, and the iBGP EVPN session towards the spine with `advertise-all-vni`.
- [`_prando-a-1_host`](./_prando-a-1_host), [`_prando-a-2_host`](./_prando-a-2_host), [`_prando-a-3-host`](./_prando-a-3-host): assign the access IP (`30.1.1.x/24`) to `eth0` on each host.

### Usage

1. Open [`P3.gns3project`](./P3.gns3project) in GNS3 and start every node.
2. On each host console, apply its `_host` script.
3. On `router-prando-a-1`'s console, apply [`_prando-a-1`](./_prando-a-1) first (it must come up before the leafs can peer with it).
4. On each leaf console (`router-prando-a-2/3/4`), apply its own numbered script (`_prando-a-2`, `_prando-a-3`, `_prando-a-4`).
5. From the spine, check that OSPF adjacencies and BGP EVPN sessions came up:
   ```bash
   vtysh -c "show ip ospf neighbor"
   vtysh -c "show bgp l2vpn evpn summary"
   vtysh -c "show bgp l2vpn evpn route"
   ```
6. Verify the overlay: all three hosts should be able to reach each other on `30.1.1.0/24` purely through the EVPN-advertised VNI 10:
   ```bash
   ping 30.1.1.2   # from host-1, via the EVPN overlay
   ```

### Notes

- All routers share the **same** BGP AS (`router bgp 1`) — this is an **iBGP** EVPN overlay with the spine acting as route reflector, not an inter-AS eBGP design.
- `bgp listen range 1.1.1.0/24 peer-group ibgp` on the spine means leafs don't need to be individually declared there: any BGP speaker sourcing from a `1.1.1.0/24` loopback and configured to peer with `1.1.1.1` is accepted automatically.
- Compared to [P2](../P2), no `ip link ... type vxlan remote/group` peer is configured manually: BGP EVPN discovers remote VTEPs and installs them dynamically once `advertise-all-vni` is in effect.
