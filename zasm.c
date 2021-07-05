/*
typedef struct MnemoStruct {

	const char name[4];
	uint8_t	args_format;
	uint8_t sz;
	uint8_t code_start;

} MnemoStruct;
*/
/*

    Copyright (c) 2021 joonicks

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
#include <stdint.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#define	MNEMO_TABLE 1
#include "bizzas.h"

#define MSGLEN	2048

int fdwrite(int, const char *, ...);
char *fdread(int, char *, char *);

#define LABLEN	32

typedef struct LabelEnt
{

	char	name[LABLEN];
	int	address;

} LabelEnt;

const char regs[5][2] = { "A", "B", "C", "D", "" };

#define MAXLABELS	500

LabelEnt labels[MAXLABELS];

uint8_t memory[65536];

/*
 *  returns NULL or non-zero length string
 *  callers responsibility that src is not NULL
 */
char *chop(char **src)
{
	char	*tok,*cut = *src;

	while(*cut && *cut == ' ')
		cut++;

	if (*cut)
	{
		tok = cut;
		while(*cut && *cut != ' ')
			cut++;
		*src = cut;
		while(*cut && *cut == ' ')
			cut++;
		**src = 0;
		*src = cut;
	}
	else
	{
		tok = NULL;
	}
	return(tok);
}

int mnemonic_match(const char *input)
{
	int	i,e;

	for(e=0;mnemonic_match_table[e].name[0];e++)
	{
		for(i=0;;i++)
		{
			if (mnemonic_match_table[e].name[i] == 0)
			{
				if (input[i] == 0)
					return(e);
				break;
			}
			if (mnemonic_match_table[e].name[i] != input[i])
				break;
		}
	}
	return(-1);
}

void split(const char *in, char *aa, char *bb, int sz)
{
	const char *src;
	char	*dst;

	src = in;
	dst = aa;
	while(*src && dst < dst+sz)
	{
		if (*src == ',')
		{
			src += 1;
			break;
		}
		*dst++ = *src++;
	}
	*dst = 0;
	dst = bb;
	while(*src && dst < dst+sz)
		*dst++ = *src++;
	*dst = 0;
}

int hexdigit(char c)
{
	if (c >= '0' && c <= '9')
		return(c - '0');
	if (c >= 'a')
		c -= 32;
/*
	if (c >= 'a' && c <= 'f')
		return(c - 'a' + 10);
*/
	if (c >= 'A' && c <= 'F')
		return(c - 'A' + 10);
	return(-1);
}

int immediate(const char *imm)
{
	int	x,br,num;

	br = num = 0;
	if (*imm == '[')
	{
		imm++;
		br++;
	}
	if (*imm == '$')
	{
		imm++;
		while(*imm)
		{
			x = hexdigit(*imm);
			if (x < 0)
			{
				if (br == 0 || *imm != ']')
					return(-1);
				return(num);
			}
			num = (num * 16) + x;
			imm++;
		}
		return(num);
	}
	return(-1);
}

int translate_to_reg(const char *in)
{
	int	i;
//fdwrite(1,"ttr in %s\n",in);
	for(i=0;regs[i][0];i++)
	{
		if (strcasecmp(in,regs[i]) == 0)
			return(i);
	}
	return(-1);
}

int translate_to_regreg(const char *in)
{
	char	srcreg[40],dstreg[40];
	int	sr,dr;

	if (*in == '$')
		return(-1);
	split(in,srcreg,dstreg,40);
	sr = translate_to_reg(srcreg);
	dr = translate_to_reg(dstreg);
//fdwrite(1,"srcreg %01X dstreg %01X\n",sr,dr);
	if (sr >= 0 && dr >= 0)
	{
		return((sr << 2) + dr);
	}
	return(-1);
}

int translate_to_imm8reg(const char *in, int *imm8)
{
	char	srcimm[40],dstreg[40];
	int	dr;

	*imm8 = -1;
	if (*in != '$')
		return(-1);
	split(in,srcimm,dstreg,40);
	*imm8 = immediate(srcimm);
	dr = translate_to_reg(dstreg);
//fdwrite(1,"imm %i, dr %i\n",*imm8,dr);
	if (*imm8 >= 0 && *imm8 <= 255 && dr >= 0)
	{
		return((dr << 2) + dr);
	}
	return(-1);
}
int translate_to_imm(const char *in, int *imm)
{
	*imm = immediate(in);
	if (*imm >= 0 && *imm <= 65535)
		return(0);
	return(-1);
}

/*
	FOO A, [$addr]
	FOO [$addr], A
*/
int translate_to_addreg(const char *in, int *addr)
{
	char	srcimm[40],dstreg[40];
	int	dr;

	if (*in == '[')
		split(in,srcimm,dstreg,40);
	else
		split(in,dstreg,srcimm,40);

	*addr = immediate(srcimm);
	dr = translate_to_reg(dstreg);
fdwrite(1,"to_addreg: '%s' '%s' $%04X\n",srcimm,dstreg,*addr);

	if (*addr >= 0 && *addr <= 65535)
		return(dr);
	return(-1);
}

int add_out(int data, int *addr)
{
	if (*addr < 0 || *addr >= 65536)
		return(-1);
	memory[*addr] = data;
	*addr += 1;
	return(0);
}

int main(int argc, char **argv)
{
	const char *opname;
	char	c,*src,*dst,*line,restbuffer[MSGLEN],linebuffer[MSGLEN];
	int	i,m,fd,org,imx,imy,maxmnemo,opcode,codemod,address;

	for (m=0;m<MSGLEN;m++)
		restbuffer[m] = 0;

	/* open file */
	if (argc < 2)
		exit(2);
	fd = open(argv[1],O_RDONLY);
	if (fd < 0)
		exit(3);

	org = 0;
	address = 0;

	/* initialize memory */
	for(m=0;m<65536;m++)
		memory[m] = 0;

	for(m=0;m<MAXLABELS;m++)
	{
		labels[m].name[0] = 0;
		labels[m].address = -1;
	}

	for(maxmnemo=0;mnemonic_match_table[maxmnemo].name[0];maxmnemo++);

	maxmnemo--;

	fdwrite(1,"file open, maxmnemo = %i %s\n",maxmnemo,mnemonic_match_table[maxmnemo].name);

	/* get a line */
	do
	{
		line = fdread(fd,restbuffer,linebuffer);
		if (line == NULL)
		{
			if (errno == EAGAIN)
				continue;
			break;
		}

		/* convert tabs to spaces */
		for(src=line;*src;src++)
			if (*src == '\t')
				*src = ' ';

		fdwrite(1,">> line: '%s'\n",line);

		// strip comments
		for(src=line;*src;src++)
		{
			if (*src == ';')
			{
				*src = 0;
				break;
			}
		}

		src = chop(&line);
		m = 0;
		/* process directives */
		if (src && *src == '.')
		{
			if (strcasecmp(src,".org") == 0)
			{
				m = immediate(line);
				if (m >= 0 && m <= 65535)
				{
					if (address != org)
					{
						fdwrite(2,"Error: Can't alter ORG after data has been added\n");
						exit(7);
					}
					org = m;
					address = m;
					fdwrite(1,"set org = $%04X (%i)\n",org,org);
				}
			}
		}

		// catch labels
		for(dst=src;*dst;dst++)
		{
			if (dst[0] == ':' && dst[1] == 0)
			{
				*dst = 0;
				m = 1;
			}
		}
		if (m == 1)
		{
			if (strlen(src) >= LABLEN)
			{
				fdwrite(1,"Error: Label too long: '%s'\n",src);
				exit(9);
			}
			for(i=0;i<MAXLABELS;i++)
				if (labels[m].name[0] == 0)
					break;
			if (i<MAXLABELS)
			{
				strcpy(labels[i].name,src);
				labels[i].address = address;
				fdwrite(1,"Label '%s' $%04X\n",src,address);
			}

			if (line == NULL || *line == 0)
				continue;
			src = chop(&line);
		}


		m = mnemonic_match(src);

		if (m >= 0 && m <= maxmnemo)
		{
			opcode = mnemonic_match_table[m].code_start;
			imx = imy = -1;
			src = dst = line;
			for(;*src;)
			{
				c = *(src++);
				if (c != ' ')
					*(dst++) = c;
			}
			*dst = 0;
			opname = mnemonic_match_table[m].name;

			// figure out argument syntax
			do
			{
				codemod = -1;
				switch(mnemonic_match_table[m].args_format)
				{
				case REG:
					codemod = translate_to_reg(line);
					break;
				case REG_REG:
					codemod = translate_to_regreg(line);
					break;
				case IMM8_REG:
					codemod = translate_to_imm8reg(line,&imx);
					break;
				case IMM16:
					codemod = translate_to_imm(line,&imx);
					if (imx < 0 || imx > 65535)
						imx = -1;
					imy = imx >> 8;
					imx = imx & 0xFF;
					break;
				case IMM8:
					codemod = translate_to_imm(line,&imx);
					if (imx < 0 || imx > 255)
						imx = -1;
					break;
				case ADDR16_REG:
					codemod = translate_to_addreg(line,&imx);
					if (imx < 0 || imx > 65535)
						imx = -1;
					imy = imx >> 8;
					imx = imx & 0xFF;
					break;
				case REL8:
				case ADDR8_REG:
				case ADDR8REG_REG:
					break;
				}
				if (codemod >= 0)
				{
					opcode += codemod;
					line = "";
					break;
				}
				m++;
				if (mnemonic_match_table[m].name[0] != ' ')
					break;
			}
			while(1);

			i = mnemonic_match_table[m].sz;
			add_out(opcode,&address);
			if (i == 2)
			{
				add_out(imx,&address);
				/* add relocation entry for a REL8 */
			}
			if (i == 3)
			{
				add_out(imx,&address);
				add_out(imy,&address);
				/* add relocation entry for a IMM16 */
			}

			fdwrite(1,"[$%04X] %i $%02X %02X %02X %s '%s'\n",address,i,opcode,imx,imy,opname,line);
		}
	}
	while(1);

	close(fd);

	/* insert label addresses into placeholder positions */

	for(i=1,m=org;m<address;i++,m++)
	{
		fdwrite(1,"$%02X ",memory[m]);
		if ((i & 7) == 0)
		{
			i = 0;
			fdwrite(1,"\n");
		}
	}
	fdwrite(1,"\n");
}

