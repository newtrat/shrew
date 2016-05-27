#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <stdio.h>
#include <error.h>
#include <unistd.h>

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
	server_addr.sin_port = htons(4444);
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
	
	printf("Received a packet on port: %d and addr %d\n", ntohs(cli_addr.sin_port), cli_addr.sin_addr.s_addr);

	close(sockfd);
	return cli_addr;
}

int main(int argc, char* argv[]) {
	struct sockaddr_in friend_addr = waitForStartSignal();
	
	int friend_sock = socket(PF_INET, SOCK_DGRAM, 0);
	
	for (int i = 0; i < 100; i++) {
		int sockfd = 0;
		char* message = "Testing";
		ssize_t n = sendto(friend_sock, message, strlen(message) + 1, 0, 
		                    (struct sockaddr *) &friend_addr, sizeof(friend_addr));
		if (n < 0) {
			error(1, 0, "Error writing to socket");
		}
	}
}
