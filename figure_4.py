import matplotlib.pyplot as plt
import numpy

BURST_PARAMS_FILE = "data/current/burst_params.txt"
THROUGHPUT_FILE = "data/current/throughput.txt"
OUTPUT_FILE = "data/current/figure_4.png"

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

# Aggregate data per burst period
aggregate_data = {}
for i in range(len(periods)):
	period = periods[i]
	throughput = throughputs[i]
	if not period in aggregate_data:
		aggregate_data[period] = []
	aggregate_data[period].append(throughput)

# Compute mean and stdevmean for each period
xaxis = []
yaxis = []
yerror = []
for period, value in sorted(aggregate_data.iteritems()):
	xaxis.append(period)
	yaxis.append(numpy.average(aggregate_data[period]))
	yerror.append(numpy.std(aggregate_data[period], ddof=1) / numpy.sqrt(len(aggregate_data[period])))

#plt.figure()
plt.errorbar(xaxis, yaxis, yerr=yerror, fmt='o')
#plt.plot(periods, throughputs, marker='o')
plt.xlabel("Time between bursts (ms)")
plt.ylabel("Average Throughput (Mbps)")
plt.title("Throughput vs. burst period (burst length = 150 ms)")
plt.savefig(OUTPUT_FILE)
plt.show()
