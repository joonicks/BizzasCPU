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
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <stdint.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#define	MNEMO_TABLE 1
#define EXCL_MNEMONICS_GLOBAL 1
extern const char * const regs[];
#include "bizzas.h"

#define VERSION	"zasm v0.2, 2021-10-20"

#define MSGLEN	2048

int fdwrite(int, const char *, ...);
char *fdread(int, char *, char *);
int disass(uint8_t *data, char *code, int sz);

#define LABLEN	32

typedef struct LabelEnt
{

	char	name[LABLEN];
	int	address;

} LabelEnt;

#define MAXLABELS	500

LabelEnt labels[MAXLABELS];

uint8_t memory[65536];

int matchlabel(const char *token)
{
	int	n;

	for(n=0;n<MAXLABELS;n++)
	{
		if (labels[n].name[0] != *token)
			continue;
		if (strcmp(labels[n].name,token) == 0)
			return(n);
	}
	return(-1);
}

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

void copytoken(const char *src, char *dst)
{
	while(*src)
	{
		if (*src == '\t' || *src == ' ' || *src == '\r' || *src == '\n')
			break;
		*dst++ = *src++;
	}
	*dst = 0;
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
	for(i=0;i<4;i++)
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

void help(const char *exec)
{
	fdwrite(1,"Usage: %s [options] <input-file>\n", exec);
	fdwrite(1,"-h, --help\tdisplay this help and exit\n");
	fdwrite(1,"-v\t\tbe verbose\n");
	fdwrite(1,"--version\toutput version information and exit\n");
	exit(5);
}

int main(int argc, char **argv)
{
	const char *src,*inputfile;
	char	c,*dst,*line,restbuffer[MSGLEN],linebuffer[MSGLEN],das[MSGLEN];
	int	i,m,fd,org,imx,imy,maxmnemo,opcode,codemod,address,_addr;

	for (m=0;m<MSGLEN;m++)
		restbuffer[m] = 0;

	inputfile = NULL;
	if (argc < 2)
		exit(2);
	for(i=1;i<argc;i++)
	{
		src = argv[i];
		if (src && *src && *src == '-')
		{
			switch(src[1])
			{
			case 'h':
				help(argv[0]);
			case '-':
				if (strcmp("version",&src[2]) == 0)
				{
					fdwrite(1,"%s\n", VERSION);
					exit(6);
				}
				if (strcmp("help",&src[2]) == 0)
					help(argv[0]);
			default:
				fdwrite(2,"error: unknown option: %s\n", src);
				exit(1);
			}
		}
		else
		if (src && *src)
		{
			if (inputfile)
			{
				fdwrite(2,"error: multiple input files or unknown options\n");
				exit(4);
			}
			else
			{
				inputfile = src;
			}
		}
	}
	if (inputfile == NULL)
	{
		fdwrite(2,"error: no input file\n");
		exit(2);
	}
	/* open file */
	fd = open(inputfile,O_RDONLY);
	if (fd < 0)
	{
		fdwrite(2,"error opening input file: %s\n", strerror(errno));
		exit(3);
	}

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
		for(dst=line;*dst;dst++)
			if (*dst == '\t')
				*dst = ' ';

		while(*line == ' ')
			line++;
		fdwrite(1,"input> %s\n",line);

		// strip comments
		for(dst=line;*dst;dst++)
		{
			if (*dst == ';')
			{
				*dst = 0;
				break;
			}
		}

		src = chop(&line);
		/* skip full comment lines */
		if (src == NULL)
			continue;

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
			continue;
		}

		// catch labels
		for(dst=(char *)src;*dst;dst++)
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
				fdwrite(2,"Error: Label too long: '%s'\n",src);
				exit(9);
			}
			m = matchlabel(src);
			if (m != -1)
			{
				fdwrite(2,"Error: duplicate label: '%s'\n",src);
				exit(10);
			}
			for(i=0;i<MAXLABELS;i++)
				if (labels[i].name[0] == 0)
					break;
			if (i<MAXLABELS)
			{
				strcpy(labels[i].name,src);
				labels[i].address = address;
				fdwrite(1,"label> %s [$%04X]\n",src,address);
			}

			if (line == NULL || *line == 0)
				continue;
			src = chop(&line);
		}

		m = mnemonic_match(src);

		copytoken(line,das);
		i = matchlabel(das);
		if (i >= 0)
		{
			sprintf(das,"$%04X",labels[i].address);
			line = das;
		}

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
				case IMM16_REG:
					codemod = translate_to_addreg(line,&imx);
					if (imx < 0 || imx > 65535)
						imx = -1;
					imy = imx >> 8;
					imx = imx & 0xFF;
					break;
				case REL8:
				case EIMM8_REG:
				case ECD_REG:
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

			_addr = address;
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

			disass(&memory[_addr], das, MSGLEN);
			for(src=das;*src;src++)
				if (*src == '\t')
					break;
			fdwrite(1,"output> %s\n", (src && *src == '\t') ? &src[1] : das);
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

