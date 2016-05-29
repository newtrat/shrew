Launch an Amazon EC2 Ubuntu instance using the instructions from PA2 (on Piazza).  Make sure the username is 'ubuntu' (the default).  
In a terminal, run
1. sudo apt-get update  
2. sudo apt-get install git  
3. git clone https://github.com/newtrat/shrew.git  
4. cd shrew  
5. chmod 776 run.sh  
6. sudo ./run.sh [Hit Enter and y when prompted near the start of the script.]  
Note that this script will take a very long time (potentially up to 12 hours) to run.  

If you don’t want to leave your ssh session running for that long, feel free to detach the run script:  

tmux  
sudo ./run.sh  
Ctrl-b d  
The graphs we’ve used in this blog post are stored in data/name_of_experiment (also copies are stored in timestamped folders corresponding to the time that experiment completed; the pictures inside those folders have meaningful names).  

Also, if your EC2 instance seems slow (slow to download dependencies - the tests will take a while to run but print output periodically), create a new on and hope for better load balancing =D