#!/bin/bash
HOST=$MAHIMAHI_BASE
UDP_PORT=1234

# Payload for a full-length, 1500 byte packet assuming IP header is 20 bytes and UDP header is 8 bytes
FULL_PACKET=""
for i in {1..736}
do
	FULL_PACKET=1$FULL_PACKET
done

echo -n $FULL_PACKET > /dev/udp/$HOST/$UDP_PORT