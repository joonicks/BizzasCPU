/*

    Copyright (c) 2018-2021 joonicks

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
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include "bizzas.h"

#define MSGLEN	2048

int fdwrite(int, const char *, ...);

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

char *DST = "DST";
char *SRC = "SRC";
char *IMM16ADR = "[IMM16]";
char *IMM16 = "IMM16";
char *IMM8ADR = "[E:IMM8]";
char *IMM8 = "IMM8";
char *REL8 = "REL8";
char *REGADDR = "[E:REG]";

int disass(uint8_t *data, char *code, int sz)
{
	const char	*opcode,*mod,*dst;
	char	immer[20];
	int	imm16,imm8;
	int	im,id,bit;

	opcode = mnemonics[data[0]];

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
		bit = (irop & 0x04) >> 2;
		if (irop & 0x08)
		{
			im = (irop & 3);
			mod = SRC;
			sprintf(immer,"[E:%s]",regs[2+bit]);
			dst = immer;
		}
		else
		{
			sprintf(immer,"[E:%s]",regs[2+bit]);
			mod = immer;
			dst = DST;
		}
		break;
	case 3:
		break;
	case 4:
		break;

	case 5:
		dst = DST;
		break;

	case 6:
		if (irop & 8)
		{
			dst = DST;
		}
		break;

	case 8:
	case 9:
	case 10:
	case 11:
	case 12:
	case 13:
	case 14:
	case 15:
		mod = SRC;
		dst = DST;
		if (im == id)
		{
			mod = IMM8;
			imm8 = 1;
		}
		break;
	case 7:
	default:
		mod = SRC;
		dst = DST;
	}
	switch(irop)
	{
	case 48:
		dst = "C:D";
	case 50:
		mod = "MR";
		break;
	case 49:
		mod = "C:D";
		break;
	case 96:
	case 97:
		mod = regs[4];
		dst = regs[2 + (irop & 1)];
		break;
	case 98:
	case 99:
		dst = regs[4];
		mod = regs[2 + (irop & 1)];
		break;
	}

	if (mod == SRC)
		mod = regs[im];
	if (dst == DST)
		dst = regs[id];

	if (mod == REGADDR)
	{
		sprintf(immer,"[$%02X:%s]",data[1],regs[im]);
		mod = immer;
	}
	if (dst == REGADDR)
	{
		sprintf(immer,"[$%02X:%s]",data[1],regs[id]);
		dst = immer;
	}

	if (mod == IMM8)
	{
		sprintf(immer,"$%02X",data[1]);
		mod = immer;
	}

	if (mod == IMM8ADR)
	{
		sprintf(immer,"[E:$%02X]",data[1]);
		mod = immer;
	}
	if (mod == IMM16ADR)
	{
		sprintf(immer,"[$%04X]",data[1] | ((int)data[2] << 8));
		mod = immer;
	}

	if (dst == IMM8ADR)
	{
		sprintf(immer,"[E:$%02X]",data[1]);
		dst = immer;
	}
	if (dst == IMM16ADR)
	{
		sprintf(immer,"[$%04X]",data[1] | ((int)data[2] << 8));
		dst = immer;
	}

	if (mod == IMM16)
	{
		sprintf(immer,"$%04X",data[1] | ((int)data[2] << 8));
		mod = immer;
	}

	if (mod == REL8)
	{
		sprintf(immer,"%c$%02X",(data[1] & 0x80) ? '-' : '+',data[1] & 0x7F);
		mod = immer;
	}

	if (code)
	{
		snprintf(code,sz,"hex %02X bin %s:\t%s   %s%s%s",irop,mkbin(irop),opcode,mod,(*mod && *dst) ? ", " : "",dst);
	}
	return(1 + imm8 + imm16);
}
