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

#ifndef BIZZAS_H
#define BIZZAS_H 1

#ifndef EXCL_MNEMONICS_GLOBAL

const char * const regs[] = { "A", "B", "C", "D", "E", "MR" };

const char * const mnemonics[] = {
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",	//00
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",

	// 16..19 LD [imm16], dst
	"LD ",	"LD ",	"LD ",	"LD ",
	// 20..23 ST src, [imm16]
	"ST ",	"ST ",	"ST ",	"ST ",	//10

	// 24..27 LD [E:imm8], dst
	"LD ",	"LD ",	"LD ",	"LD ",
	// 28..31 ST src, [E:imm8]
	"ST ",	"ST ",	"ST ",	"ST ",

	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	"LD ",	//20
	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",	"ST ",

	"MOV",	"JMP",	"JMP",	"...",	"...",	"...",	"...",	"...",	//30
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",

	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",	//40
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",

	"SHR",	"SHR",	"SHR",	"SHR",	"SHL",	"SHL",	"SHL",	"SHL",	//50
	"RCR",	"RCR",	"RCR",	"RCR",	"RCL",	"RCL",	"RCL",	"RCL",

	"MOV",	"MOV",	"MOV",	"MOV",	"...",	"...",	"...",	"...",	//60
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

#endif /* ifndef EXCL_MNEMONICS_GLOBAL */

#ifdef MNEMO_TABLE

#define	IMM16		1
#define IMM8		2
#define REL8		3
#define IMM16_REG	4
#define EIMM8_REG	5
#define ECD_REG		6
#define REG		7
#define REG_REG		8
#define IMM8_REG	9

typedef struct MnemoStruct {

	const char name[4];
	uint8_t	args_format;
	uint8_t sz;
	uint8_t code_start;
	uint8_t code_mask;

} MnemoStruct;

MnemoStruct mnemonic_match_table[] =
{
{	"JMP",	IMM16,		3,	0x00,	0xFF	},
{	" ",	REL8,		2,	0x08,	0xFF	},
{	"NOP",	IMM16,		3,	0x01,	0xFF	},
{	" ",	IMM8,		2,	0x09,	0xFF	},
{	"JNC",	IMM16,		3,	0x02,	0xFF	},
{	" ",	REL8,		2,	0x0A,	0xFF	},
{	"JC",	IMM16,		3,	0x03,	0xFF	},
{	" ",	REL8,		2,	0x0B,	0xFF	},
{	"JNZ",	IMM16,		3,	0x04,	0xFF	},
{	" ",	REL8,		2,	0x0C,	0xFF	},
{	"JZ",	IMM16,		3,	0x05,	0xFF	},
{	" ",	REL8,		2,	0x0D,	0xFF	},
{	"JNS",	IMM16,		3,	0x06,	0xFF	},
{	" ",	REL8,		2,	0x0E,	0xFF	},
{	"JS",	IMM16,		3,	0x07,	0xFF	},
{	" ",	REL8,		2,	0x0F,	0xFF	},

{	"LD",	IMM16_REG,	3,	0x10,	0xFC	},
{	" ",	EIMM8_REG,	2,	0x18,	0xFC	},
{	" ",	ECD_REG,	2,	0x20,	0xFC	},
{	"ST",	IMM16_REG,	3,	0x14,	0xFC	},
{	" ",	EIMM8_REG,	2,	0x1C,	0xFC	},
{	" ",	ECD_REG,	2,	0x30,	0xFC	},

{	"SHR",	REG,		1,	0x50,	0xFC	},
{	"SHL",	REG,		1,	0x54,	0xFC	},
{	"RCR",	REG,		1,	0x58,	0xFC	},
{	"RCL",	REG,		1,	0x5C,	0xFC	},
{	"INC",	REG,		1,	0x68,	0xFC	},
{	"DEC",	REG,		1,	0x6C,	0xFC	},
{	"XOR",	REG_REG,	1,	0x70,	0xF0	},

{	"ADD",	REG_REG,	1,	0x80,	0xF0	},
{	" ",	IMM8_REG,	2,	0x80,	0xF0	},
{	"AND",	REG_REG,	1,	0x90,	0xF0	},
{	" ",	IMM8_REG,	2,	0x90,	0xF0	},
{	"OR",	REG_REG,	1,	0xA0,	0xF0	},
{	" ",	IMM8_REG,	2,	0xA0,	0xF0	},
{	"ADC",	REG_REG,	1,	0xB0,	0xF0	},
{	" ",	IMM8_REG,	2,	0xB0,	0xF0	},
{	"CMP",	REG_REG,	1,	0xC0,	0xF0	},
{	" ",	IMM8_REG,	2,	0xC0,	0xF0	},
{	"SUB",	REG_REG,	1,	0xD0,	0xF0	},
{	" ",	IMM8_REG,	2,	0xD0,	0xF0	},
{	"SBC",	REG_REG,	1,	0xE0,	0xF0	},
{	" ",	IMM8_REG,	2,	0xE0,	0xF0	},
{	"MOV",	REG_REG,	1,	0xF0,	0xF0	},
{	" ",	IMM8_REG,	2,	0xF0,	0xF0	},
{	"",	0,		0,	0,	0	},
};

#endif /* ifdef MNEMO_TABLE */
#endif /* ifndef BIZZAS_H */
