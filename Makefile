CC = gcc

.PHONY:		all

all:		disass zasm example_opcodelist.txt example_disassembly.txt

disass:		disass.c io.o bizzas.h
		$(CC) -g -pipe -Os -Wall -o disass disass.c io.o

example_opcodelist.txt:	disass
		./disass --oplist > example_opcodelist.txt

example_disassembly.txt: disass
		./disass random.bin > example_disassembly.txt

io.o:		io.c
		$(CC) -g -pipe -Os -Wall -c $<

zasm:		zasm.c bizzas.h io.o
		$(CC) -g -pipe -Os -Wall -o zasm zasm.c io.o
