#!/bin/bash

# Step -1: Install dependencies
# apt-get update
# apt-get install ......

# Step 0: chmod all the things
# chmod 777 ....

# Step 1: Set up Apache and index file.
# service start apache2
# ./make_long_index.sh 10000

# Step 2: Set up attacker.
# ./shrew.sh or whatever

# Step 3: Change min RTO and launch link
# TODO: Change user in the mm-delay command if running on EC2!
#       Just needs to be non-root...
./change_rto.sh &
sudo -u cs244 mm-delay 6 mm-link onePointFive.trace onePointFive.trace \
				   				 --uplink-queue=droptail \
				   				 --uplink-queue-args='bytes=22500' \
				   				 --downlink-queue=droptail \
				   				 --downlink-queue-args='bytes=22500' \
				   				 -- \
  <<< './client_and_friend.sh'