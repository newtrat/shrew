sleep 1 # So mm-link has time to process
ip route > /tmp/ip_routes.txt
grep -i 'delay-' /tmp/ip_routes.txt > /tmp/grep_results.txt
ip route change `cat /tmp/grep_results.txt` rto_min 1000
ip route flush cache