/*
 *  davec.h
 *  Carousel
 *
 *  Created by Dave Carlton on 05/27/08.
 *  Copyright 2008 Polymicro Systems. All rights reserved.
 *
 */

extern Boolean			gVerbose;
extern int				gDebugLevel;
extern int				gVerboseIndex;
extern Boolean			gVerboseStack[256];


#define NSLogF(a) \
do { NSString *logstring = @"%s: "; \
logstring = [logstring stringByAppendingString:a]; \
NSLog(logstring, __PRETTY_FUNCTION__); \
} while(0)

#define NSLogFunc	NSLog(@"%s", __PRETTY_FUNCTION__)

#define PMLOG(ARGS...) PM_LogInternal(__FILE__, __PRETTY_FUNCTION__, ## ARGS)
#define NSLOGVF(x)	if (gVerbose) NSLog(@"%s: %s: %d", __PRETTY_FUNCTION__, x)


