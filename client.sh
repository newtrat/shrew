#!/bin/bash
if [ $# -ne 2 ]
then
  echo "Usage: ./client.sh file_size_megabits output_filename"
fi

start_time=$(date +"%s%3N")
curl -s $MAHIMAHI_BASE > /dev/null
end_time=$(date +"%s%3N")
delta_time=$((end_time - start_time))
echo "CURL took $delta_time milliseconds on a $1 megabit file"
throughput=$(bc -l <<< "1000.0*$1/$delta_time")
echo "Throughput: $throughput Mbps"
echo "$throughput" >> $2