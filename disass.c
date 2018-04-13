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

/*
if (IROP[7] + IROP[6] + IROP[5] + IROP[3]) == 0 then 3 byte instruction
if (IROP[7] + IROP[6]) == 0 then 2+ byte instruction
else 1 byte instruction
*/

int regs_needed(void)
{
	if ((irop & 0xE8) == 0) // b11101000
		return(3);
	if ((irop & 0xC0) == 0) // b11000000
		return(2);
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
		to_file(1,"\t0x%02X\t\t\t; %s (%02X) Undefined opcode\n",irop,mkbin(irop),irop);
		return;
	case 2:
		to_file(1,"\t0x%02X 0x%02X\t\t; %s (%02X) Undefined opcode\n",irop,ira,mkbin(irop),irop);
		return;
	case 3:
		to_file(1,"\t0x%02X 0x%02X 0x%02X\t\t; %s (%02X) Undefined opcode\n",irop,ira,irb,mkbin(irop),irop);
		return;
	}
}

char *jumps[] = { "JNC", "JC", "JNZ", "JZ", "JNE", "JE", NULL, "JMP" };
char *xxsrc[] = { "A", "B", "C", "D" };
char *aluop[] = { "ADD", "XOR", "AND", "OR" };
char *rraddr[] = { "C:D", "C:D", "A:B", "A:B" };

void printopcode(void)
{
	char	*addr,*opcode;
	int	xx,yy,ss,rr;

	opcode = NULL;

	switch(irop >> 4)
	{
	case 0: // JMP IMM16
		opcode = jumps[(irop & 7)];
		if (irop < 8 && opcode)
		{
			to_file(1,"\t%s\t#%02X%02X\t\t; %s (%02X) arg=%02X%02X\n",opcode,ira,irb,mkbin(irop),irop,ira,irb);
			return;
		}
		if (irop >= 8 && opcode)
		{
			to_file(1,"\t%s\t%c#%02X\t\t; %s (%02X) arg=%02X\n",
				opcode,((ira & 128) == 0) ? '+' : '-',(ira & 0x7F),mkbin(irop),irop,ira);
			return;
		}
		break;
	case 1:
		// ST, LD [IMM16]
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
		// ST/LD [R1:R2]...
		if ((irop & 8) == 8)
		{
			rr = (irop & 3);
			if ((irop & 4) == 0)
				to_file(1,"\tST\t[%s], %s\t; %s (%02X)\n",rraddr[rr],xxsrc[rr],mkbin(irop),irop);
			else
				to_file(1,"\tLD\t%s, [%s]\t; %s (%02X)\n",xxsrc[rr],rraddr[rr],mkbin(irop),irop);
			return;
		}
		break;
	case 2: //0011SSYY ALU IMM8        PC++, ALUOP=SS, SRC=IRA, DST=YY
		ss = ((irop >> 2) & 3);
		yy = (irop & 3);
		to_file(1,"\t%s\t%s, #%02X\t\t; %s (%02X) arg=%02X\n",aluop[ss],xxsrc[yy],ira,mkbin(irop),irop,ira);
		return;
	case 3: // LD IMM8
		xx = ((irop >> 2) & 3);
		if (xx == 1) // LD R1, IMM8
		{
			yy = (irop & 3);
			to_file(1,"\tLD\t%s, #%02X\t\t; %s (%02X) arg=%02X\n",xxsrc[yy],ira,mkbin(irop),irop,ira);
			return;
		}
		if ((irop & 0x0f) < 2)
		{
			yy = ((~irop) & 1)*2;
			to_file(1,"\tST\t[%s], #%02X\t; %s (%02X) arg=%02X\n",rraddr[yy],ira,mkbin(irop),irop,ira);
			return;
		}
		break;
	case 4:
		break;
	case 5:
	case 6:
		break;
	case 7: // 0111XXYY CMP R1, R2
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (xx != yy) // comparing registers to themselves always results in EQUAL=TRUE
		{
			to_file(1,"\tCMP\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
			return;
		}
		break;
	case 8: // 1000#### JMP [R1:R2]
		addr = ((irop & 8) == 0) ? "A:B" : "C:D";
		opcode = jumps[(irop & 7)];
		if (opcode)
			to_file(1,"\t%s\t%s\t\t; %s (%02X)\n",opcode,addr,mkbin(irop),irop);
		else
			to_file(1,"\tHALT\t\t\t; %s (%02X)\n",mkbin(irop),irop);
		return;
	case 9: // 1001XXYY ALU ADC
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		to_file(1,"\tADC\t%s, %s\t\t; %s (%02X)\n",xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
		return;
	case 10:
	case 11: // ALU SUB/SBC XXYY
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (xx != yy) // SUB/SBC with itself is unproductive, use XOR
		{
			opcode = ((irop & 16) == 0) ? "SUB" : "SBC";
			to_file(1,"\t%s\t%s, %s\t\t; %s (%02X)\n",opcode,xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
			return;
		}
		break;
	case 12:
	case 13:
	case 14:
	case 15: // ALU OP 11SSXXYY, NOP
		if (irop == 255)
		{
			to_file(1,"\tNOP\t\t\t; %s (%02X)\n",mkbin(irop),irop);
			return;
		}
		ss = ((irop >> 4) & 3);
		xx = ((irop >> 2) & 3);
		yy = (irop & 3);
		if (ss >= 2 && xx == yy) // AND/OR with itself isnt productive
			break;
		to_file(1,"\t%s\t%s, %s\t\t; %s (%02X)\n",aluop[ss],xxsrc[yy],xxsrc[xx],mkbin(irop),irop);
		return;
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

