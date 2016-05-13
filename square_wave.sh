#!/bin/bash
HOST="10.0.2.15"
UDP_PORT=1234

# Payload for a full-length, 1500 byte packet assuming IP header is 20 bytes and UDP header is 8 bytes
FULL_PACKET=""
for i in {1..736}
do
	FULL_PACKET=1$FULL_PACKET
done

# width of square, given in milliseconds
WAVE_WIDTH=100
# LINE_RATE is given in packets per millisecond
LINE_RATE=125

# Delay between squares, in milliseconds
DELAY=900

# Number repetitions
NUM_REPS=10

for ((i=0; i<$NUM_REPS; i++))
do
	# Send all the packets in one big burst
	# TODO:  make it actually a square wave
	for ((j=0; j<$(($WAVE_WIDTH*$LINE_RATE)); j++))
	do
		echo -n $FULL_PACKET > /dev/udp/$HOST/$UDP_PORT
	done
	sleep 0.9
done
