#!/bin/bash
start_time=$(date +"%s%3N")
curl -s $MAHIMAHI_BASE > /dev/null
end_time=$(date +"%s%3N")
delta_time=$((end_time - start_time))
echo "CURL took $delta_time milliseconds on a $1 megabit file"
throughput=$(bc -l <<< "1000.0*$1/$delta_time")
echo "Throughput: $throughput Mbps"