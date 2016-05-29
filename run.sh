#!/bin/bash

# Starter stuff
add-apt-repository ppa:keithw/mahimahi
apt-get update
apt-get install mahimahi mininet gcc make apache2 python-matplotlib

make

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.tcp_congestion_control=reno

mkdir data
mkdir data/current

chmod 776 *.sh
chmod 776 *.py

# Mininet version:
#
DATA_DIR=data/current
BURST_OUTFILE=$DATA_DIR/burst_params.txt
THROUGHPUT_OUTFILE=$DATA_DIR/throughput.txt

chmod 666 $DATA_DIR

#
##First graph is the general graph of the entire range, small file
python mininet_test.py --min-period=500 --max-period=1500 --period-step=100 \
                       --min-length=150 --max-length=150  --length-step=50 \
                       --trials=3 --file-size-megabits=40 \
                       --burst-outfile=$BURST_OUTFILE \
                       --throughput-outfile=$THROUGHPUT_OUTFILE
timestamp=$(date +%Y-%m-%d:%H:%M:%S)
#
python figure_4.py --plot-name="Small File 5 Trials"
#
cp -r $DATA_DIR data/$timestamp
#
##Second graph is the zoomed graph for a small file
#python mininet_test.py --min-period=1000 --max-period=1500 --period-step=50 \
#                       --min-length=150 --max-length=150 --length-step=50 \
#                       --trials=5 --file-size-megabits=8 \
#                       --burst-outfile=$BURST_OUTFILE \
#                       --throughput-outfile=$THROUGHPUT_OUTFILE
#timestamp=$(date +%Y-%m-%d:%H:%M:%S)
#
#python figure_4.py --plot-name="Small File 10 Trial Zoom"
#
#cp -r $DATA_DIR data/$timestamp


# Mahimahi version:

# Parameters:
INDEX_SIZE_MEGABITS=8
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
touch $BURST_PARAM_FILE
touch $THROUGHPUT_FILE

MIN_BURST_PERIOD=500 #in ms
MAX_BURST_PERIOD=1500
BURST_PERIOD_INCREMENT=50

username="ubuntu"
if id "cs244" >/dev/null 2>&1; then
  username="cs244"
fi

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
chmod 666 $BURST_PARAM_FILE
chmod 666 $THROUGHPUT_FILE
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
  for ((trials=0; trials<5; trials+=1))
  do

    echo "Burst period: $burst_period ms   Burst length: $burst_length ms"
    echo "$burst_period $burst_length" >> $BURST_PARAM_FILE

    ./attacker $burst_period $burst_length &
    attacker_pid=$!

    ./change_rto.sh &
    sudo -u $username mm-delay 6 mm-link onePointFive.trace onePointFive.trace \
                                         --uplink-queue=droptail \
                                         --uplink-queue-args='packets=15' \
                                         --downlink-queue=droptail \
                                         --downlink-queue-args='packets=15' \
                                         -- \
      <<< ". client_and_friend.sh $INDEX_SIZE_MEGABITS $THROUGHPUT_FILE"
    kill -9 $attacker_pid
  done
done

# Step 3: Graph output, save in timestamped form
python ./figure_4.py --plot-name="Mahimahi Small File 5 Trials"
timestamp=$(date +%Y-%m-%d:%H:%M:%S)
cp -r data/current data/$timestamp
