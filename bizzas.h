/*

    Copyright (c) 2018-2021 proton

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
