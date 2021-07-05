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

char *mnemonics[] = {
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",	//00
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",

	"LD ",	"LD ",	"LD ",	"LD ",	"ST ",	"ST ",	"ST ",	"ST ",	//10
	"LD ",	"LD ",	"LD ",	"LD ",	"ST ",	"ST ",	"ST ",	"ST ",

	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	//20
	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",
	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	//30
	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",

	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",	//40
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",

	"SHR",	"SHR",	"SHR",	"SHR",	"SHL",	"SHL",	"SHL",	"SHL",	//50
	"RCR",	"RCR",	"RCR",	"RCR",	"RCL",	"RCL",	"RCL",	"RCL",

	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",	//60
	"INC",	"INC",	"INC",	"INC",	"DEC",	"DEC",	"DEC",	"DEC",
	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	//70
	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",
	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	//80
	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",	"ADD",
	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	//90
	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",
	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	//A0
	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",
	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	//B0
	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",	"ADC",
	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	//C0
	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",	"CMP",
	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	//D0
	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",	"SUB",
	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	//E0
	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",	"SBC",
	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	//F0
	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV",	"MOV"
	};


#ifdef MNEMO_TABLE

#define	IMM16		1
#define IMM8		2
#define REL8		3
#define ADDR16_REG	4
#define ADDR8_REG	5
#define ADDR8REG_REG	6
#define REG		7
#define REG_REG		8
#define IMM8_REG	9

typedef struct MnemoStruct {

	const char name[4];
	uint8_t	args_format;
	uint8_t sz;
	uint8_t code_start;

} MnemoStruct;

MnemoStruct mnemonic_match_table[] =
{
{	"JMP",	IMM16,		3,	0x00	},
{	" ",	REL8,		2,	0x08	},
{	"NOP",	IMM16,		3,	0x01	},
{	" ",	IMM8,		2,	0x09	},
{	"JNC",	IMM16,		3,	0x02	},
{	" ",	REL8,		2,	0x0A	},
{	"JC",	IMM16,		3,	0x03	},
{	" ",	REL8,		2,	0x0B	},
{	"JNZ",	IMM16,		3,	0x04	},
{	" ",	REL8,		2,	0x0C	},
{	"JZ",	IMM16,		3,	0x05	},
{	" ",	REL8,		2,	0x0D	},
{	"JNS",	IMM16,		3,	0x06	},
{	" ",	REL8,		2,	0x0E	},
{	"JS",	IMM16,		3,	0x07	},
{	" ",	REL8,		2,	0x0F	},

{	"LD",	ADDR16_REG,	3,	0x10	},
{	" ",	ADDR8_REG,	2,	0x18	},
{	" ",	ADDR8REG_REG,	2,	0x20	},
{	"ST",	ADDR16_REG,	3,	0x14	},
{	" ",	ADDR8_REG,	2,	0x1C	},
{	" ",	ADDR8REG_REG,	2,	0x30	},

{	"SHR",	REG,		1,	0x50	},
{	"SHL",	REG,		1,	0x54	},
{	"RCR",	REG,		1,	0x58	},
{	"RCL",	REG,		1,	0x5C	},
{	"INC",	REG,		1,	0x68	},
{	"DEC",	REG,		1,	0x6C	},
{	"XOR",	REG_REG,	1,	0x70	},

{	"ADD",	REG_REG,	1,	0x80	},
{	" ",	IMM8_REG,	2,	0x80	},
{	"AND",	REG_REG,	1,	0x90	},
{	" ",	IMM8_REG,	2,	0x90	},
{	"OR",	REG_REG,	1,	0xA0	},
{	" ",	IMM8_REG,	2,	0xA0	},
{	"ADC",	REG_REG,	1,	0xB0	},
{	" ",	IMM8_REG,	2,	0xB0	},
{	"CMP",	REG_REG,	1,	0xC0	},
{	" ",	IMM8_REG,	2,	0xC0	},
{	"SUB",	REG_REG,	1,	0xD0	},
{	" ",	IMM8_REG,	2,	0xD0	},
{	"SBC",	REG_REG,	1,	0xE0	},
{	" ",	IMM8_REG,	2,	0xE0	},
{	"MOV",	REG_REG,	1,	0xF0	},
{	" ",	IMM8_REG,	2,	0xF0	},
{	"",	0,		0,	0	},
};

#endif /* if 0 */
