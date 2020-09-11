/*

    Copyright (c) 2018-2020 proton

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

uint8_t	irop, ira, irb;

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

char *mnemo[] = {
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",	//00
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",
	"LD ",	"LD ",	"LD ",	"LD ",	"ST ",	"ST ",	"ST ",	"ST ",	//10
	"LD ",	"LD ",	"LD ",	"LD ",	"ST ",	"ST ",	"ST ",	"ST ",
	"CMP",	"CMP",	"CMP",	"CMP",	"SUB",	"SUB",	"SUB",	"SUB",	//20
	"SBC",	"SBC",	"SBC",	"SBC",	"ADC",	"ADC",	"ADC",	"ADC",
	"ADD",	"ADD",	"ADD",	"ADD",	"XOR",	"XOR",	"XOR",	"XOR",	//30
	"AND",	"AND",	"AND",	"AND",	"OR ",	"OR ",	"OR ",	"OR ",
	"MOV",	"MOV",	"MOV",	"MOV",	"LD ",	"LD ",	"ST ",	"ST ",	//40
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",	//50
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",	//60
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",
	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	//70
	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",
	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	//80
	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",
	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	//90
	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",
	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	//A0
	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",
	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	//B0
	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",
	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	//C0
	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",
	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	//D0
	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",
	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	//E0
	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",
	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	//F0
	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR "
	};

char *regs[] = { "A", "B", "C", "D" };

char *DST = "DST";
char *SRC = "SRC";
char *IMM16ADR = "[IMM16]";
char *IMM16 = "IMM16";
char *IMM8ADR = "[IMM8]";
char *IMM8 = "IMM8";
char *REL8 = "REL8";
char *CDADDR = "[C:D]";

int disass(uint8_t *data)
{
	char	*opcode,*mod,*dst;
	char	immer[20];
	int	imm16,imm8;
	int	im,id;

	opcode = mnemo[data[0]];

	irop = data[0];
	im = ((irop >> 2) & 3);
	id = (irop & 3);
	mod = "";
	dst = "";
	imm16 = 0;
	imm8 = 0;
	switch(irop >> 4)
	{
	case 0:
		mod = (irop & 0x08) ? REL8 : IMM16;
		imm16 = (irop & 0x08) ? 1 : 0;
		imm8 = 1;
		if ((irop & 0x07) == 1)
			mod = (irop & 0x08) ? IMM8 : IMM16;
		break;
	case 1:
		if (irop & 0x08)
		{
			mod = (irop & 0x04) ? SRC : IMM8ADR;
			dst = (irop & 0x04) ? IMM8ADR : DST;
			if (irop & 0x04)
				im = ((irop >> 2) & 3);
			imm16 = 0;
		}
		else
		{
			mod = (irop & 0x04) ? SRC : IMM16ADR;
			dst = (irop & 0x04) ? IMM16ADR : DST;
			imm16 = 1;
		}
		if (irop & 0x04)
			im = (irop & 3);
		imm8 = 1;
		break;
	case 2:
	case 3:
		mod = IMM8;
		dst = DST;
		imm8 = 1;
		break;
	case 4:
		if ((irop & 0x0c) == 0)
		{
			mod = IMM8;
			dst = DST;
		}
		if ((irop & 0x0c) == 4)
		{
			im = id = irop & 1;
			mod = (irop & 2) ? SRC : CDADDR;
			dst = (irop & 2) ? CDADDR : SRC;
		}
		break;
	case 5:
	case 6:
		break;
	default:
		mod = SRC;
		dst = DST;
	}

	if (mod == SRC)
		mod = regs[im];
	if (dst == DST)
		dst = regs[id];

	if (mod == IMM8)
		sprintf((mod = immer),"$0x%02X",data[1]);
	if (mod == IMM8ADR)
		sprintf((mod = immer),"[0x%02X]",data[1]);
	if (mod == IMM16ADR)
		sprintf((mod = immer),"[0x%04X]",data[1] | ((int)data[2] << 8));

	if (dst == IMM8)
		sprintf((dst = immer),"$0x%02X",data[1]);
	if (dst == IMM8ADR)
		sprintf((dst = immer),"[0x%02X]",data[1]);
	if (dst == IMM16ADR)
		sprintf((dst = immer),"[0x%04X]",data[1] | ((int)data[2] << 8));

	if (mod == IMM16)
		sprintf((mod = immer),"0x%04X",data[1] | ((int)data[2] << 8));

	if (mod == REL8)
		sprintf((mod = immer),"%c0x%02X",(data[1] & 0x80) ? '-' : '+',data[1] & 0x7F);

	to_file(1,"hex 0x%02X bin %s: \t%s   %s%s %s\n",irop,mkbin(irop),opcode,mod,(*dst) ? "," : "",dst);
	return(1 + imm8 + imm16);
}

int main(int argc, char **argv)
{
	uint8_t	data[512];
	int	fd,n,i;

	if (argc == 2 && strcmp(argv[1],"--oplist") == 0)
	{
		data[2] = 0x12;
		data[1] = 0x34;
		for(i=0;i<256;i++)
		{
			data[0] = i;
			disass(data);
		}
		exit(0);
	}

	if (argv[1])
	{
		fd = open(argv[1],O_RDONLY);
		if (fd < 0)
			exit(1);
		while((n = read(fd,data,sizeof(data))) > 0)
		{
			i = 0;
			while(i < n)
				i += disass(&data[i]);
		}
		close(fd);
	}
	return(0);
}

