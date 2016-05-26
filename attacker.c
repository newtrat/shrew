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
int waitForStartSignal() {
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
	int clisockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
	printf("Accepted connection.\n");
	if (clisockfd < 0) {
		error(1, 0, "Error on accept");
	}

	close(sockfd);
	return clisockfd;
}

int main(int argc, char* argv[]) {
	int sockfd = waitForStartSignal();
	for (int i = 0; i < 100; i++) {
		char* message = "Testing";
		ssize_t n = write(sockfd, message, strlen(message) + 1);
		if (n < 0) {
			error(1, 0, "Error writing to socket");
		}
	}
	close(sockfd);
}
