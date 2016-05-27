#!/bin/bash

# Step -2: Install dependencies
# echo 'Installing dependencies...'
# apt-get update
# apt-get install ......

# Step -1: Compile
# echo 'Compiling...'
make

# Step 0: chmod all the things
chmod 775 ./attacker
chmod 775 ./client_and_friend.sh
chmod 775 ./client.sh
chmod 775 ./make_long_index.sh
# etc.

# Step 1: Set up server and attacker
# echo 'Starting server...'
# service start apache2
# ./make_long_index.sh 10000
# echo 'Starting attacker...'
./attacker &
attacker_pid=$!

# Step 2: Change min RTO and launch link
# TODO: Change user in the mm-delay command if running on EC2!
#       Just needs to be non-root...
# echo 'Starting client...'
./change_rto.sh &
sudo -u cs244 mm-delay 6 mm-link onePointFive.trace onePointFive.trace \
                                 --uplink-queue=droptail \
                                 --uplink-queue-args='bytes=22500' \
                                 --downlink-queue=droptail \
                                 --downlink-queue-args='bytes=22500' \
                                 -- \
  <<< '. client_and_friend.sh'
kill -9 $attacker_pid