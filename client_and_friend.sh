# Wait 2 seconds for RTO switch to happen
sleep 2
# Spawn attacker friend (send a UDP packet to attacker)
echo -n "Hello, Shrew!" > /dev/udp/${MAHIMAHI_BASE}/42000 &
# Spawn client(s?)
./client.sh $1 $2 &
# Wait for everybody to finish
wait