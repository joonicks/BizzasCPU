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

#define MSGLEN 2048

int fdwrite(int, const char *, ...);
int disass(uint8_t *data, char *code, int sz);

int main(int argc, char **argv)
{
	char	code[MSGLEN];
	uint8_t	data[512];
	int	fd,n,i;

	if (argc == 2 && strcmp(argv[1],"--oplist") == 0)
	{
		data[2] = 0x12;
		data[1] = 0x34;
		for(i=0;i<256;i++)
		{
			data[0] = i;
			disass(data,code,MSGLEN);
			fdwrite(1,"%s\n",code);
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
			{
				i += disass(&data[i],code,MSGLEN);
				fdwrite(1,"%s\n",code);
			}
		}
		close(fd);
	}
	return(0);
}

