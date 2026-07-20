# P1 — FRR router bring-up

### Description

The goal of this lab is to get a minimal FRRouting environment running inside GNS3 before touching any routing protocol. Knowledge acquired through it is:
- Building a custom Docker image on top of `frrouting/frr` with the daemons it needs enabled.
- Understanding the FRR daemon set (`zebra`, `bgpd`, `ospfd`, `isisd`) and what each one is responsible for.
- Starting FRR inside a container via an entrypoint script and reaching its `vtysh` console.

### Topology

Two nodes, directly connected:

- **`host-prando-a-1`**: an Alpine container (`iproute2`, `iputils`, `bash`, `tcpdump`, `vim`) used as a plain traffic endpoint.
- **`routeur-prando-a`**: an FRRouting container with `zebra`, `bgpd`, `ospfd` and `isisd` daemons enabled, but with empty config files — routing is meant to be configured interactively from this base.

### Files

- [`P1.gns3project`](./P1.gns3project): the GNS3 topology (open it with GNS3 to load both nodes).
- [`_prando-a-1_host`](./_prando-a-1_host): Dockerfile for the Alpine host.
- [`_prando-a-2`](./_prando-a-2): Dockerfile for the FRR router — installs the packages, creates empty daemon config files under `/etc/frr/`, enables `zebra`, `bgpd`, `ospfd` and `isisd` in `/etc/frr/daemons`, and sets [`start.sh`](./start.sh) as entrypoint.
- [`start.sh`](./start.sh): entrypoint script, starts FRR (`frrinit.sh`, `watchfrr`) in the background and drops into an interactive `bash` so the container stays alive and usable from the GNS3 console.

### Usage

1. Build the two images referenced by the GNS3 templates (note the `-f` flag: the Dockerfiles have no `.dockerfile`/`Dockerfile` extension):
   ```bash
   docker build -t router:latest -f _prando-a-2 .
   docker build -t host:latest   -f _prando-a-1_host .
   ```
2. Open [`P1.gns3project`](./P1.gns3project) in GNS3 and start both nodes.
3. Open a console on `routeur-prando-a` and enter the FRR CLI:
   ```bash
   vtysh
   ```
4. From here, interfaces and protocols (OSPF, BGP, IS-IS) can be configured manually — this lab intentionally ships with empty daemon configs as a starting point for [P2](../P2) and [P3](../P3).

### Notes

- **Daemons**: `bgpd` exchanges routes between Autonomous Systems; `ospfd` and `isisd` are interior gateway protocols used to compute shortest paths inside a single AS.
- Config files are `chown`'d to the `frr` user and `chmod 640` to match FRR's expected permissions — writing them as any other user/mode will make `zebra`/`bgpd` refuse to start.
