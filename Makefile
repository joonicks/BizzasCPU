CC = gcc

.PHONY:		all

all:		disass opcodelist.txt example_disassembly.txt

disass:		disass.c
		$(CC) -g -pipe -Os -Wall -o disass $<

opcodelist.txt:	disass
		./disass --oplist > opcodelist.txt

example_disassembly.txt: disass
		./disass random.bin > example_disassembly.txt
