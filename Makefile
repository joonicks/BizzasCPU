CC = gcc

.PHONY:		all

all:		disass example_opcodelist.txt example_disassembly.txt

disass:		disass.c
		$(CC) -g -pipe -Os -Wall -o disass $<

example_opcodelist.txt:	disass
		./disass --oplist > example_opcodelist.txt

example_disassembly.txt: disass
		./disass random.bin > example_disassembly.txt
