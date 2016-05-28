#!/usr/bin/python
from mininet.topo import Topo
from mininet.node import CPULimitedHost
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

  def build(self):
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
    return

def main():
  os.system("mn -c")
  for burst_period in [1100]:
    for burst_length in [150]:
      topo = ShrewTopo()
      net = Mininet(topo=topo, host=CPULimitedHost, link=TCLink)
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
      attacker_friend.cmd("echo -n 'Hello, Shrew!' > /dev/udp/" + attacker.IP() + "/42000 &")

      proc = client.popen("curl -o /dev/null -s -w %{time_total} " + server.IP() + "/webserver/index.html", shell=True)
      (stdoutdata, stderrdata) = proc.communicate()
      print "Burst period: %d   Time: %s" % (burst_period, stdoutdata)

      net.stop()
      # Ensure that all processes you create within Mininet are killed.
      # Sometimes they require manual killing.
      Popen("pgrep -f webserver.py | xargs kill -9", shell=True).wait()

if __name__ == "__main__":
  main()