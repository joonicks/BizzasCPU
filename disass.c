/*

    Copyright (c) 2018 proton

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#define MSGLEN	2048

#define uint8_t unsigned char

char	gsockdata[MSGLEN];

/*
 *  Format text and send to a socket or file descriptor
 */
int to_file(int sock, const char *format, ...)
{
	va_list msg;

	if (sock == -1)
		return(-1);

	va_start(msg,format);
	vsprintf(gsockdata,format,msg);
	va_end(msg);

	return(write(sock,gsockdata,strlen(gsockdata)));
}

uint8_t		irop, ira, irb;		// executor registers
int		regsloaded = 0;
int		undefined = 0;

int regs_needed(void)
{
	switch(irop >> 4)
	{
	case 0:
	case 1:
		return(3); // irop+ira+irb
	case 2:
	case 3:
	case 4:
		return(2); // irop+ira
	}
	return(1); // irop only
}

char *mkbin(uint8_t a)
{
	static char	tmp[10];

	tmp[0] = ((a & 128) == 128) ? '1' : '0';
	tmp[1] = ((a & 64) == 64) ? '1' : '0';
	tmp[2] = ((a & 32) == 32) ? '1' : '0';
	tmp[3] = ((a & 16) == 16) ? '1' : '0';
	tmp[4] = ((a & 8) == 8) ? '1' : '0';
	tmp[5] = ((a & 4) == 4) ? '1' : '0';
	tmp[6] = ((a & 2) == 2) ? '1' : '0';
	tmp[7] = ((a & 1) == 1) ? '1' : '0';
	tmp[8] = 0;
	return(tmp);
}

void printunknown(void)
{
	undefined++;
	switch(regs_needed())
	{
	case 1:
		to_file(1,"\t0x%02X\t\t\t; %s Undefined opcode\n",irop,mkbin(irop));
		return;
	case 2:
		to_file(1,"\t0x%02X 0x%02X\t\t; %s Undefined opcode\n",irop,ira,mkbin(irop));
		return;
	case 3:
		to_file(1,"\t0x%02X 0x%02X 0x%02X\t\t; %s Undefined opcode\n",irop,ira,irb,mkbin(irop));
		return;
	}
}

char *jumps[] = { "JNC", "JC", "JNZ", "JZ", "JNE", "JE", NULL, "JMP" };
char *xxsrc[] = { "A", "B", "C", "D" };
char *aluop[] = { "AND", "OR", "XOR", "ADD" };
char *rraddr[] = { "A:B", "C:D" };

void printopcode(void)
{
	char	*addr,*opcode;
	int	xx,yy,ss;

	opcode = NULL;

	switch(irop >> 4)
	{
	case 0:
		opcode = jumps[(irop & 7)];
		if (irop < 8 && opcode)
		{
			to_file(1,"\t%s\t#%02X%02X\t\t; %s (%02X) arg=%02X%02X\n",opcode,ira,irb,mkbin(irop),irop,ira,irb);
			return;
		}
		break;
	case 1: // ST, LD [IMM16]
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (xx == 0)
		{
			to_file(1,"\tST\t[%02X%02X], %s\t; %s (%02X) arg=%02X%02X\n",ira,irb,xxsrc[yy],mkbin(irop),irop,ira,irb);
			return;
		}
		else
		if (xx == 1)
		{
			to_file(1,"\tLD\t%s, [%02X%02X]\t; %s (%02X) arg=%02X%02X\n",xxsrc[yy],ira,irb,mkbin(irop),irop,ira,irb);
			return;
		}
	case 2:
		break;
	case 3: //0011SSYY ALU IMM8        PC++, ALUOP=SS, SRC=IRA, DST=YY
		ss = ((irop >> 2) & 3);
		yy = (irop & 3);
		to_file(1,"\t%s\t%s, #%02X\t\t; %s (%02X)\n",aluop[ss],xxsrc[yy],ira,mkbin(irop),irop);
		return;
	case 4:
		break;
	case 5:
		break;
	case 6:
		break;
	case 7: // CMP
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (xx != yy) // comparing registers to themselves always results in EQUAL=1
		{
			to_file(1,"\tCMP\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
			return;
		}
		break;
	case 8: // JMP
		addr = ((irop & 8) == 0) ? "A:B" : "C:D";
		opcode = jumps[(irop & 7)];
		if (opcode)
		{
			to_file(1,"\t%s\t%s\t\t; %s (%02X)\n",opcode,addr,mkbin(irop),irop);
			return;
		}
		break;
	case 9: // 1001XXXX        ALU ADC                         PC++, ALUOP=11, SUB=0, CARRY=C, SRC=XX, DST=YY
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		to_file(1,"\tADC\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
		return;
	case 10: // ALU OR XXYY
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (xx != yy) // OR with itself isnt productive
		{
			to_file(1,"\tOR\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
			return;
		}
		break;
	case 11: // ST/LD 0RRR, 1RRR
		xx = (irop & 3);
		yy = ((irop > 1) & 1);
		if ((irop & 8) == 0)
			to_file(1,"\tST\t[%s], %s\t; %s (%02X)\n",rraddr[yy],xxsrc[xx],mkbin(irop),irop);
		else
			to_file(1,"\tLD\t%s, [%s]\t; %s (%02X)\n",xxsrc[xx],rraddr[yy],mkbin(irop),irop);
		return;
	case 12: // ALU XOR XXYY
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		to_file(1,"\tXOR\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
		return;
	case 13: // ALU ADD XXYY
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		to_file(1,"\tADD\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
		return;
	case 14: // ALU SUB XXYY
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (xx != yy) // OR with itself isnt productive
		{
			to_file(1,"\tSUB\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
			return;
		}
		break;
	case 15: // ALU AND XXYY, NOP
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (xx != yy) // AND with itself isnt productive
		{
			to_file(1,"\tAND\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
			return;
		}
		if (irop == 255)
		{
			to_file(1,"\tNOP\t\t\t; %s (%02X)\n",mkbin(irop),irop);
			return;
		}
		break;
	default:
		exit(16);
	}
	printunknown();
}

void disass(uint8_t data)
{
	switch(regsloaded++)
	{
	case 0:
		irop = data;
		break;
	case 1:
		ira = data;
		break;
	case 2:
		irb = data;
		break;
	default:
		to_file(2,"error! error Will Robinson!\n");
	}
	if (regsloaded < regs_needed())
		return;

	regsloaded = 0;
	printopcode();
}

int main(int argc, char **argv)
{
	uint8_t	data[512];
	int	fd,n,i;

	if (argc == 2 && strcmp(argv[1],"--oplist") == 0)
	{
		ira = 0x12;
		irb = 0x34;
		undefined = 0;
		for(i=0;i<256;i++)
		{
			irop = i;
			printopcode();
		}
		to_file(1,"%i undefined opcodes\n",undefined);
		exit(0);
	}

	if (argv[1])
	{
		fd = open(argv[1],O_RDONLY);
		if (fd < 0)
			exit(1);
		while((n = read(fd,data,sizeof(data))) > 0)
		{
			for(i=0;i<n;i++)
				disass(data[i]);
		}
		close(fd);
	}
	return(0);
}

