#!/bin/bash
# Parameters:
INDEX_SIZE_MEGABITS=15
INDEX_SIZE_KILOBYTES=$((INDEX_SIZE_MEGABITS*128))

BURST_PARAM_FILE="data/current/burst_params.txt"
THROUGHPUT_FILE="data/current/throughput.txt"
if [ -f $BURST_PARAM_FILE ]
then
  rm $BURST_PARAM_FILE
fi
if [ -f $THROUGHPUT_FILE ]
then
  rm $THROUGHPUT_FILE
fi

MIN_BURST_PERIOD=500 #in ms
MAX_BURST_PERIOD=500
BURST_PERIOD_INCREMENT=50

# Step -2: Install dependencies
# echo 'Installing dependencies...'
# apt-get update
# apt-get install ......

# Step -1: Compile, add files
# echo 'Compiling...'
make
mkdir -p data/current

# Step 0: chmod all the things
chmod 775 ./attacker
chmod 775 ./client_and_friend.sh
chmod 775 ./client.sh
chmod 775 ./make_long_index.sh
# etc.

# Step 1: Set up server
# echo 'Starting server...'
# service start apache2
./make_long_index.sh $INDEX_SIZE_KILOBYTES
# echo 'Starting attacker...'

# Step 2: (Repeatedly) attack!!!
burst_length=150
for ((burst_period=$MIN_BURST_PERIOD; burst_period<=$MAX_BURST_PERIOD; \
      burst_period+=$BURST_PERIOD_INCREMENT))
do
  echo "Burst period: $burst_period ms   Burst length: $burst_length ms"
  echo "$burst_period $burst_length" >> $BURST_PARAM_FILE

  ./attacker $burst_period $burst_length &
  attacker_pid=$!

  ./change_rto.sh &
  sudo -u cs244 mm-delay 6 mm-link onePointFive.trace onePointFive.trace \
                                   --uplink-queue=droptail \
                                   --uplink-queue-args='bytes=22500' \
                                   --downlink-queue=droptail \
                                   --downlink-queue-args='bytes=22500' \
                                   -- \
    <<< ". client_and_friend.sh $INDEX_SIZE_MEGABITS $THROUGHPUT_FILE"
  kill -9 $attacker_pid
done

# Step 3: Graph output, save in timestamped form
python ./figure_4.py
timestamp=$(date +%Y-%m-%d:%k:%M:%S)
cp -r data/current data/$timestamp