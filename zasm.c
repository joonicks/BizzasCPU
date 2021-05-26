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

char *mnemo[] = {
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",	//00
	"JMP",	"NOP",	"JNC",	"JC ",	"JNZ",	"JZ ",	"JNS",	"JS ",
	"LD ",	"LD ",	"LD ",	"LD ",	"ST ",	"ST ",	"ST ",	"ST ",	//10
	"LD ",	"LD ",	"LD ",	"LD ",	"ST ",	"ST ",	"ST ",	"ST ",
	"LD ",	"LD ",	"ST ",	"ST ",	"LD ",	"LD ",	"ST ",	"ST ",	//20
	"LD ",	"LD ",	"ST ",	"ST ",	"LD ",	"LD ",	"ST ",	"ST ",
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",	//30
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",
	"...",	"...",	"...",	"...",	"...",	"...",	"...",	"...",	//40
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
	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	//D0
	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",	"AND",
	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	//E0
	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",	"OR ",
	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	//F0
	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR",	"XOR"
	};

char *regs[] = { "A", "B", "C", "D" };

