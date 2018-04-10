CC = gcc

.PHONY:		all

all:		disass opcodelist.txt

disass:		disass.c
		$(CC) -Wall -o disass $<

opcodelist.txt:	disass
		./disass --oplist > opcodelist.txt
