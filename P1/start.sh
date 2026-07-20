# Starting FRR in background.
/usr/lib/frr/frrinit.sh start
/usr/lib/frr/watchfrr -d zebra bgpd ospfd isisd
# Leaving interactive bash to allow command terminal access.
exec bash