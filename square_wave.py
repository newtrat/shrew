#!/usr/bin/python
import time
import os

BYTES_PER_SECOND = 1500000.0 / 8.0
TIME_BW_PACKETS =  1500.0 / BYTES_PER_SECOND

# width of square, given in seconds
WAVE_WIDTH = 100.0 / 1000.0

# Delay between starts of squares, in seconds
DELAY = 1.0

# Number repetitions
NUM_REPS=10

def now():
  return os.times()[4]

for i in range(NUM_REPS):
  start_time = now()
  # Perform burst:
  packets_sent = 0
  while now() - start_time < WAVE_WIDTH:
    packets_sent += 1
    os.system("./send_packet.sh")
    sleep_time = start_time + TIME_BW_PACKETS - now()
    if sleep_time > 0:
      time.sleep(sleep_time)
    print now()
    
  print packets_sent
  # Wait until next burst time:
  sleep_time = start_time + DELAY - now()
  if sleep_time > 0:
    time.sleep(sleep_time)