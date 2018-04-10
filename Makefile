CC = gcc
disass:		disass.c
		$(CC) -Wall -o disass $<
