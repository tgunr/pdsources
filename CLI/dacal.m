/***********************************
* Command line tool to test the dacalLib
************************************/

#include <getopt.h>
#include <stdlib.h>
#import "dacallib.h"
#import <PMSUtility/pms.h>

char* STDCStringCreateFromCFString( CFStringRef inString )
{
	char*	cstring;
	CFIndex	maxlen;
	Boolean	goodCoerce = FALSE;

	maxlen = CFStringGetMaximumSizeForEncoding( CFStringGetLength( inString ), kCFStringEncodingUTF8 ) + 1;
	cstring = (char*)calloc( 1, maxlen );
	if( cstring != NULL ) goodCoerce = CFStringGetCString(inString, cstring, maxlen, kCFStringEncodingUTF8);
	if( !goodCoerce & (cstring != NULL) ) {
		free( cstring );
		cstring = NULL;
	}
	return cstring;
}

void CFStringPrint( CFStringRef inString, Boolean releaseInString )		//	Outputs a CFString to stdout, and optionally releases it.
{
	char* outputString = NULL;
	
	if(inString == NULL) return;
	outputString = STDCStringCreateFromCFString( inString );
	if(outputString) {
		fprintf(stdout, outputString);
		free(outputString);
	}		
	if( releaseInString ) CFRelease( inString );
	
	return;
}

void usage() {
	printf("dacal [--reset] [--close|-k] [--led 0|1] [--model] [-uid] [--devices]  \n");
	printf("      [--slot number] [--status|-i] [--reference|-c number] [--verbose|-b] \n");
	printf("      [--get-slot] [--dvd|-v number] [--eject] \n");
	exit(1);
}

int main (int argc, const char * argv[]) {
	int ch;	
	
	struct option longopts[] = {
		{ "help",				no_argument,            NULL,				'h'	},
		{ "reset",				no_argument,            NULL,				'r'	},
		{ "close",				no_argument,            NULL,				'k'	},
		{ "led",				required_argument,      NULL,				'l'	},
		{ "model",				no_argument,            NULL,				'm'	},
		{ "uid",				no_argument,            NULL,				'u'	},
		{ "slot",				required_argument,      NULL,				's' },
		{ "devices",			no_argument,			NULL,				'd' },
		{ "get-slot",			no_argument,            NULL,				'g'	},
		{ "status",				no_argument,            NULL,				'i'	},
		{ "verbose",			no_argument,            NULL,				'b'	},
		{ "reference",			required_argument,      NULL,				'c'	},
		{ "dvd",				required_argument,      NULL,				'v'	},
		{ "eject",				no_argument,            NULL,				'e'	},
		{ NULL,         0,								NULL,				0	}
	};
	
	int option_index = 0;

	DACALResult		err = 0;	
	DACALDeviceRef	workDevice = 1;
	DACALCount		workCount = 0;
	DACALSlotNum	workSlot = 0;
	CFStringRef		workCFString, modelCFString, nameCFString;
	CFUUIDRef		workCFUUID;
	
	if (argc == 1 ) {
		usage();
		return 1;
	}

	err = DACALDevicesInitialize();

	while (true) {
		if (err) {
			printf("dacal: device error %x", err);
			return 1;
		}
		ch = getopt_long(argc, (char * const *)argv, "hrkl:muds:ic:bgve", longopts, &option_index);
		if (ch == -1)
			break;
		switch (ch) {
			case 0: {
#ifdef __DCDEBUG_
				printf("option %s", longopts[option_index].name);
				if (optarg)
					printf(" with arg %s", optarg);
				printf ("\n");
#endif
				switch (option_index) {
					case 3: {
						err = DACALCommandSetLED( workDevice, atoi(optarg));
						break;
					}
				}
				break;
			}
																		// help
			case 'h': {
				usage();
				return 1;
			}
																		// reset
			case 'r': {
				err = DACALCommandReset( workDevice );				
				break;
			}
																		// close
			case 'k': {
				err = DACALCommandCloseDoor( workDevice );				
				break;
			}
																		// led
			case 'l': {
				err = DACALCommandSetLED( workDevice, atoi(optarg));
				break;
			}
																		// model
			case 'm': {
				modelCFString = (CFStringRef)DACALCommandCopyModel( workDevice, &err );
				if(modelCFString) workCFString = CFStringCreateWithFormat( NULL, NULL, CFSTR("Model Number: %@\n"), modelCFString );
				else workCFString = CFSTR("Error Finding Model\n");
				
				if(workCFString) {
					CFStringPrint( workCFString, TRUE );
					workCFString = NULL;
				}
				if(modelCFString) {
					CFRelease(modelCFString);
					modelCFString = NULL;
				}
				break;
			}
																		// uid
			case 'u': {
				workCFUUID = (CFUUIDRef)DACALCommandCopyUUID( workDevice, &err );
				if(workCFUUID) workCFString = CFStringCreateWithFormat( NULL, NULL, CFSTR("Model UID: %@\n"), workCFUUID );
				else workCFString = CFSTR("Error Finding UID\n");
				
				if(workCFString) {
					CFStringPrint( workCFString, TRUE );
					workCFString = NULL;
				}
				if(workCFUUID) {
					CFRelease(workCFUUID);
					workCFUUID = NULL;
				}
				break;
			}
																		// move to
			case 's': {
				workSlot = atoi(optarg);
				err = DACALCommandMoveToSlot( workDevice, workSlot );
				break;
			}
																		// reference
			case 'c': {
				workDevice = atoi(optarg);
				break;
			}
																		// devices
			case 'd': {
				workCount = DACALDevicesGetCount();
				int loop;
				
				printf( "Device Count: %i\n", workCount );
				if( workCount )
					for( loop=1;loop<=workCount;loop++ ) {
						modelCFString = (CFStringRef)DACALCommandCopyModel( loop, &err );
						if( modelCFString == NULL ) modelCFString = CFSTR("Unknown Model");
						
						workCFUUID = (CFUUIDRef)DACALCommandCopyUUID( loop, &err );
						if( workCFUUID == NULL ) workCFUUID = (CFUUIDRef)CFSTR("Unknown ID");
						
						nameCFString = (CFStringRef)DACALCommandCopyName( loop, &err );
						if( nameCFString == NULL ) nameCFString = CFSTR("Unnamed");
						
						workCFString = CFStringCreateWithFormat( DACALDevicesGetCFAllocator(), NULL, CFSTR("%i: %@ %@\n\tName: %@\n"), loop, workCFUUID, modelCFString, nameCFString );
						if( workCFString == NULL ) workCFString = CFSTR("Memory Error\n");

						if(workCFString) {
							CFStringPrint( workCFString, TRUE );
							workCFString = NULL;
						}
						if(modelCFString) {
							CFRelease(modelCFString);
							modelCFString = NULL;
						}
						if(nameCFString) {
							CFRelease(nameCFString);
							nameCFString = NULL;
						}
						if(workCFUUID) {
							CFRelease(workCFUUID);
							workCFUUID = NULL;
						}
					}
			
				break;
			}
																		// get dvd slot
			case 'g': {
				workSlot = DACALCommandDVDGetSlot( workDevice, &err );
				printf( "DVD Current Slot: %i\n", workSlot );
				
				break;
			}
																		// verbose
			case 'b':{
				gDebugLevel++;
				break;
			}
																		// status
			case 'i': {
				nameCFString = (CFStringRef)DACALCommandCopyStatus( workDevice, &err );
				if(workCFString) workCFString = CFStringCreateWithFormat( DACALDevicesGetCFAllocator(), NULL, CFSTR("Device status: %@\n"), nameCFString );
				else workCFString = CFSTR("Error Finding Status\n");

				if(workCFString) {
					CFStringPrint( workCFString, TRUE );
					workCFString = NULL;
				}
				if(nameCFString) {
					CFRelease(nameCFString);
					nameCFString = NULL;
				}
				break;
			}
																		// dvd move to
			case 'v': {
				workSlot = atoi(optarg);
				err = DACALCommandDVDMoveTo( workDevice, workSlot );
				break;
			}
																		// eject dvd
			case 'e': {
				err = DACALCommandDVDEject( workDevice );
				break;
			}
																		// unknown
			default:
				usage();
				return 1;
		}
	}
	argc -= optind;
    argv += optind;
	DACALDevicesFinalize();
    return 0;
}
