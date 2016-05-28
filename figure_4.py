import matplotlib.pyplot as plt

BURST_PARAMS_FILE = "data/burst_params.txt"
THROUGHPUT_FILE = "data/throughput.txt"
OUTPUT_FILE = "data/figure_4.png"

periods = []
throughputs = []
burst_length = 150

with open(BURST_PARAMS_FILE) as f:
  for line in f:
    burst_period, burst_length = line.split()
    periods.append(float(burst_period))

with open(THROUGHPUT_FILE) as f:
  for line in f:
    throughputs.append(float(line))

plt.plot(periods, throughputs, marker='o')
plt.xlabel("Time between bursts (ms)")
plt.ylabel("Throughput (Mbps)")
plt.title("Throughput vs. burst period (burst length = 150 ms)")
plt.savefig(OUTPUT_FILE)
plt.show()
