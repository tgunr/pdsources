/*
 *  pms.c
 *  PickADisk*
 *
 *  Created by Dave Carlton on 10/12/09.
 *  Copyright 2009 PolyMicro Systems. All rights reserved.
 *
 */


#include <stdio.h>
#include <stdarg.h>
#import <Cocoa/Cocoa.h>
#include <sys/time.h>
#include <CoreServices/CoreServices.h>
#include "pms.h"

#ifdef __DCDEBUG
Boolean			gVerbose = TRUE;
int				gDebugLevel = 7;
#else
Boolean			gVerbose = TRUE;
int				gDebugLevel = 2;
#endif

int				gVerboseIndex = 0;
Boolean			gVerboseStack[256];
UInt64			startTime = 0;

// PMLOGSetVerbose sets a new debug level
void PMLOGSetVerbose(Boolean value) { gVerbose = value; }

// PMLOGPushVerbose sets a new debug setting and saves the previous one
// Use this to reduce debug output inside loops etc.
void PMLOGPushVerbose(Boolean value) {
	gVerboseStack[gVerboseIndex] = gVerbose;
	gVerboseIndex += 1;
	if (gVerboseIndex > 256)
		gVerboseIndex = 256;
	gVerbose = value;
}

// PMLOGPopVerbose restores the previous debug setting
void PMLOGPopVerbose() {
	gVerboseIndex -= 1;
	gVerbose = gVerboseStack[gVerboseIndex];
	if (gVerboseIndex < 0)
		gVerboseIndex = 0;
}

void PM_LogInternal(const char *file, const char *function, int inLevel, char *fmt, ... )
{	
    UInt64			elapsedTime, nowTime;
    UInt64			milliSecs;
	NSString *		logString;
	NSString *		pathString = [NSString stringWithCString:file encoding:NSUTF8StringEncoding];
	const char *	fileString = [[pathString lastPathComponent] cStringUsingEncoding: NSUTF8StringEncoding];
	
	struct timeval theTime;
	
    if( inLevel > gDebugLevel )
    {
        // The level is not high enough to be displayed, we're skipping this item.
        return;
    }
    else
    {
		va_list		ap, ap2;
		int d;
		char c, *s;
		void *p;
		int result;
		
		if (startTime == 0) {
			result = gettimeofday(&theTime, NULL);
			startTime = (theTime.tv_sec*1000000) + (theTime.tv_usec);
		}
		
		result = gettimeofday(&theTime, NULL);
		
		nowTime = (theTime.tv_sec*1000000) + (theTime.tv_usec);
		elapsedTime = nowTime - startTime;
		milliSecs = (elapsedTime / 1000);
		printf("%s:%s: %0u\n\t", fileString, function, milliSecs);
		
		va_start(ap, fmt);
		va_copy(ap2, ap);
		while (*fmt) {
			c = *fmt++;
			if (c != '%') {
				printf("%c",c);
			} else {
				switch(*fmt++) {
					case 's':
						/* string */ 
						s = va_arg(ap, char *); 
						printf("%s", s); 
						break;
					case 'd':
						/* int */ 
						d = va_arg(ap, int); 
						printf("%d", d); 
						break;
					case 'x':
						/* char */ /* Note: char is promoted to int. */ 
						d = va_arg(ap, int); 
						printf("%x", d); 
						break; 
					case 'p':
						p = va_arg(ap, void *); 
						printf("%p", p); 
						break; 

				}
			}
		}
		va_end(ap); 
		/* use ap2 to iterate over the arguments again */
		va_end(ap2); 
//			NSLog(@"%s: %s: %3.3d\t", file, function, elapsedTime, inFormatString);
		printf("\n");
	}
}

void PM_LogArgs(NSString * arg1, ...) { /* print all int type args, finishing with -1 */

	const char here[] = __FILE__ ":__FUNCTION__: ";
	va_list ap;
	int i;
	NSMutableString *logstring;
	NSString *appendString;
	
	[logstring stringWithCString:here encoding:NSUTF8StringEncoding];
	
	va_start( ap, arg1 );
//	_doprnt( inFormatString, &ap, conslog_putc, 16 );
	appendString = [NSString stringWithString:arg1];
	[logstring appendString:appendString];
	va_end(ap);
	NSLog(@"%s", logstring);
}

