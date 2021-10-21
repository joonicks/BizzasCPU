CC = gcc

.PHONY:		all

all:		disass zasm example_opcodelist.txt example_disassembly.txt

example_opcodelist.txt:	disass
		./disass --oplist > example_opcodelist.txt

example_disassembly.txt: disass
		./disass random.bin > example_disassembly.txt

io.o:		io.c
		$(CC) -g -pipe -Os -Wall -c $<

libdis.o:	libdis.c bizzas.h
		$(CC) -g -pipe -Os -Wall -c $<

disass:		disass.c io.o libdis.o
		$(CC) -g -pipe -Os -Wall -o disass disass.c io.o libdis.o

zasm:		zasm.c io.o libdis.o
		$(CC) -g -pipe -Os -Wall -o zasm zasm.c io.o libdis.o
