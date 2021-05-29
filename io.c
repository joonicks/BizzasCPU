/*

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
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <errno.h>

#define MAXLEN	2048
#define MSGLEN	1024

char	globaldata[MAXLEN];

/*
 *  Format text and send to a socket or file descriptor
 */
int fdwrite(int fd, const char *format, ...)
{
	va_list msg;

	if (fd == -1)
		return(-1);

	va_start(msg,format);
	vsprintf(globaldata,format,msg);
	va_end(msg);

	return(write(fd,globaldata,strlen(globaldata)));
}

/*
 *  Read any data waiting on a socket or file descriptor
 *  and return any complete lines to the caller
 */
char *fdread(int fd, char *rest, char *line)
{
	char	*src,*dst,*rdst;
	int	n;

	errno = EAGAIN;

	src = rest;
	dst = line;

	while(*src)
	{
		if (*src == '\n' || *src == '\r')
		{
		gotline:
			while(*src == '\n' || *src == '\r')
				src++;
			*dst = 0;
			dst = rest;
			while(*src)
				*(dst++) = *(src++);
			*dst = 0;
			return((*line) ? line : NULL);
		}
		*(dst++) = *(src++);
	}
	rdst = src;

	n = read(fd,globaldata,MSGLEN-2);
	switch(n)
	{
	case 0:
		errno = EPIPE;
	case -1:
		return(NULL);
	}

	globaldata[n] = 0;
	src = globaldata;

	while(*src)
	{
		if (*src == '\r' || *src == '\n')
			goto gotline;
		if ((dst - line) >= (MSGLEN-2))
		{
			/*
			 *  line is longer than buffer, let the wheel spin
			 */
			src++;
			continue;
		}
		*(rdst++) = *(dst++) = *(src++);
	}
	*rdst = 0;
	return(NULL);
}
