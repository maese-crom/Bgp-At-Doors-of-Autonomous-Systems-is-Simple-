# P2 — Manual VXLAN L2 tunnel

### Description

The goal of this lab is to bridge two separate hosts over a VXLAN tunnel built entirely by hand, with no routing/control-plane protocol involved — a "flood-and-learn" overlay. Knowledge acquired through it is:
- Creating a Linux bridge (`br0`) and attaching both a local access port and a VXLAN interface to it.
- Building a VXLAN VTEP with `ip link ... type vxlan` and understanding its `id`, `dstport`, `local`/`remote`/`group` parameters.
- Comparing the two classic ways to discover remote VTEPs: **multicast flood-and-learn** vs. **static unicast peering**.

Both routers reuse the FRR image built in [P1](../P1) — no new Dockerfile is needed here, only interface/bridge configuration.

### Topology

```
host-1 (30.1.1.1/24) --- router-1 --- Switch-prando-a --- router-2 --- host-2 (30.1.1.2/24)
                          eth0    eth1                eth1    eth0
```

- **`routeur-prando-a-1`** / **`router-prando-a-2`**: FRR routers. `eth0` is the access port facing the local host (bridged, no IP); `eth1` is the underlay/uplink port facing `Switch-prando-a` and carries the transport IP used to source the VXLAN tunnel.
- **`host-prando-a-1`** / **`host-prando-a-2`**: Alpine hosts, one per router, each on the `30.1.1.0/24` access subnet.
- **`Switch-prando-a`**: plain GNS3 Ethernet switch providing the underlay link between both routers.

### Files

- [`P2.gns3project`](./P2.gns3project): the GNS3 topology.
- [`_prando-a-1_host`](./_prando-a-1_host) / [`_prando-a-2_host`](./_prando-a-2_host): assign the access IP (`30.1.1.1/24` / `30.1.1.2/24`) to `eth0` on each host.
- [`_prando-a-1_g`](./_prando-a-1_g) / [`_prando-a-2_g`](./_prando-a-2_g): **multicast** variant — the VXLAN interface joins multicast `group 239.1.1.1` to flood BUM traffic and dynamically learn remote VTEPs.
- [`_prando-a-1_s`](./_prando-a-1_s) / [`_prando-a-2_s`](./_prando-a-2_s): **static unicast** variant — the VXLAN interface is pinned to a single `remote`/`local` peer pair instead of a multicast group.

### Usage

1. Open [`P2.gns3project`](./P2.gns3project) in GNS3 and start every node.
2. On each host console, apply its `_host` script to bring up the access interface.
3. On each router console, apply **either** the `_g` pair **or** the `_s` pair (not both) on `routeur-prando-a-1` and `router-prando-a-2` respectively:
   ```bash
   # multicast flood-and-learn
   sh _prando-a-1_g   # on router-1
   sh _prando-a-2_g   # on router-2

   # or, static unicast peering
   sh _prando-a-1_s   # on router-1
   sh _prando-a-2_s   # on router-2
   ```
4. Verify connectivity between `host-1` and `host-2` (they now share the same broadcast domain over VXLAN VNI 10):
   ```bash
   ping 30.1.1.2   # from host-1
   ```

### Notes

- Both routers must use the **same** variant (`_g` or `_s`) — mixing a multicast VTEP on one side with a static unicast VTEP on the other will not establish the tunnel.
- This lab has no control plane: VTEP/MAC discovery relies purely on flooding (multicast BUM replication or the single static peer). [P3](../P3) replaces this manual setup with BGP EVPN.
- The `_g`/`_s` scripts carry a leftover header comment ("apply in the SWITCH_1 console") from an earlier version of the lab — `Switch-prando-a` is a plain GNS3 Ethernet switch with no console, so in this topology these commands are applied on the **routers**, as described above.
