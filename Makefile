CC=gcc
CFLAGS=-D_POSIX_C_SOURCE=199309L -std=c11

all: attacker

attacker: attacker.c
	$(CC) $(CFLAGS) -o attacker attacker.c