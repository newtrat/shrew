#!/usr/bin/python
from mininet.topo import Topo
from mininet.node import CPULimitedHost
from mininet.node import OVSController
from mininet.link import TCLink
from mininet.net import Mininet
from mininet.log import lg, info
from mininet.util import dumpNodeConnections
from mininet.cli import CLI

from subprocess import Popen, PIPE
from time import sleep, time
from multiprocessing import Process
from argparse import ArgumentParser

import sys
import os
import math

class ShrewTopo(Topo):
  "Simple topology for bufferbloat experiment."

  def __init__(self):
    Topo.__init__(self)

    attacker = self.addHost('attacker')
    server = self.addHost('server')
    client = self.addHost('client')
    attacker_friend = self.addHost('friend')

    server_switch = self.addSwitch('s1')
    client_switch = self.addSwitch('s2')

    # Non-bottleneck links
    self.addLink(attacker, server_switch, bw=1.5, delay='2ms', max_queue_size=15)
    self.addLink(server, server_switch, bw=1.5, delay='2ms', max_queue_size=15)
    self.addLink(client, client_switch, bw=1.5, delay='2ms', max_queue_size=15)
    self.addLink(attacker_friend, client_switch, bw=1.5, delay='2ms', max_queue_size=15)

    # Bottleneck link
    self.addLink(server_switch, client_switch, bw=1.5, delay='2ms', max_queue_size=15)

def parse_args():
  parser = ArgumentParser(description="Shrew test on Mininet")
  parser.add_argument('--min-period', \
                      type=int, \
                      help="Minimum burst period (ms)", \
                      default=500)
  parser.add_argument('--max-period', \
                      type=int, \
                      help="Maximum burst period (ms)", \
                      default=1500)
  parser.add_argument('--period-step', \
                      type=int, \
                      help="Increment step for burst period (ms)", \
                      default=50)
  parser.add_argument('--min-length', \
                      type=int, \
                      help="Minimum burst length (ms)", \
                      default=150)
  parser.add_argument('--max-length', \
                      type=int, \
                      help="Maximum burst length (ms)", \
                      default=150)
  parser.add_argument('--length-step', \
                      type=int, \
                      help="Increment step for burst length (ms)", \
                      default=50)
  parser.add_argument('--trials', \
                      type=int, \
                      help="Number of trials for each (period, length) pair", \
                      default=5)
  parser.add_argument('--file-size-megabits', \
                      type=int, \
                      help="File size for curl download in megaBITS", \
                      default=8)
  parser.add_argument('--burst-outfile', \
                      type=str, \
                      help="Output file for burst parameters", \
                      default="data/current/burst_params.txt")
  parser.add_argument('--throughput-outfile', \
                      type=str, \
                      help="Output file for throughput", \
                      default="data/current/throughput.txt")
  return parser.parse_args()

def main(args):
  os.system("sudo ./make_long_index.sh %d" % (args.file_size_megabits * 128))
  os.system("cp /var/www/html/index.html webserver/index.html")
  os.system("mn -c")
  with open(args.burst_outfile, "w") as burst_outfile:
    with open(args.throughput_outfile, "w") as throughput_outfile:
      for burst_period in range(args.min_period, args.max_period + 1, \
                                args.period_step):
        for burst_length in range(args.min_length, args.max_length + 1, \
                                  args.length_step):
          for trial in range(args.trials):
            topo = ShrewTopo()
            net = Mininet(topo=topo, host=CPULimitedHost, link=TCLink, \
                          controller=OVSController)
            net.start()

            # Start up server
            client = net.get("client")
            server = net.get("server")
            server.cmd("python webserver/webserver.py &")
            # Change TCP RTO on server.
            server.cmd("ip route > /tmp/ip_routes.txt")
            with open("/tmp/ip_routes.txt") as f:
              for line in f:
                server.cmd("ip route change %s rto_min 1000" % (line.strip()))
            server.cmd("ip route flush cache")
            sleep(1)

            # Start up attacker
            attacker = net.get("attacker")
            attacker_friend = net.get("friend")
            attacker.cmd("./attacker %d %d &" % (burst_period, burst_length))
            sleep(1)
            attacker_friend.cmd("echo -n 'Hello, Shrew!' > /dev/udp/" + \
                                attacker.IP() + "/42000 &")


            proc = client.popen("curl -o /dev/null -s -w %{time_total} " + \
                                server.IP() + "/webserver/index.html", \
                                shell=True)
            (stdoutdata, stderrdata) = proc.communicate()
            burst_outfile.write("%d %d\n" % (burst_period, burst_length))
            throughput = float(args.file_size_megabits) / float(stdoutdata)
            throughput_outfile.write("%f\n" % (throughput))
            print("Burst Period: %d, Throughput: %f" % (burst_period, throughput))

            net.stop()
            # Ensure that all processes you create within Mininet are killed.
            # Sometimes they require manual killing.
            Popen("pgrep -f webserver.py | xargs kill -9", shell=True).wait()

if __name__ == "__main__":
  main(parse_args())
