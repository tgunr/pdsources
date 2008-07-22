#include <malloc/malloc.h>
#include <stdio.h>
#include <stdlib.h>
#include "xattrfunctions.h"


//command forms
#define LISTER 0
#define GETTER 1
#define SETTER 2
#define DELETE 3
#define HELP 4
#define VERSION 5

#define VERSION_NUMBER "0.32"

/*	GENERAL FLOW MODEL:
 
 (A)	Try to identify a command flag,
 (B)	Set all option bits and fail if an unknown flag is encountered,
 (C)	Iterate through remaining arguments, filling up variables in a predictable pattern, calling
 our xattr functions for every file listed.
 (D)	Terminate with a result of either 0 (PASS) or -1 (FAIL).
 
 */
void version() {
	printf("xattr (Leopardly) version %s is written by Matt Lye, released under the MIT liscense.\n", VERSION_NUMBER);
}
void usage()	{
	
	printf("usage:   xattr    [-sl] file [file ...]\n");
	printf("         xattr -p [-sl] attr_name file [file...]\n");
	printf("         xattr -w [-slRC] attr_name attr_value file [file...]\n");
	printf("         xattr -d [-sl] attr_name file [file...]\n");
	printf("         xattr	  [-vh]\n\n");
	printf("The first form lists the name of all the extended attributes of the given file(s).\n");
	printf("The second form displays the value of the attribute 'attr_name' of the given file(s).\n");
	printf("The third form sets the value of the attribute 'attr_name' to 'attr_value' for the given file(s).\n");
	printf("The fourth form deletes the attribute 'attr_name' of the given file(s).\n\n");
	printf("options:  -s:  do not follow symbolic links.\n");
	printf("          -l:  long format (verbose) output in a key=value format.\n");
	printf("          -R:  replace existing values only.\n");
	printf("          -C:  create new keys only.\n");
	printf("          -v:  version information.\n");
	printf("          -h:  this help.\n");
}


int main (int argc, const char * argv[]) {
	
	
	/*	COMMAND FLAG:
	 
	 The absence of a command flag implies the 'list' command is being issued.
	 The command and option formats are backwards-compatable with the 'xattr' python script shipped with Leopard.
	 The command flag must be the first argument encountered.
	 An unknown (non-command) flag will be assumed to be an option flag.
	 
	 */
	
	int command=LISTER;												//	The command flag default is to list attributes.
	
	
	if ( argc > 1 && argv[1][0]=='-') {								//	Ensuring there is a flag argument.
		
		switch (argv[1][1]){										
				
				
			case 'd':												
				
				command = DELETE;
				break;
				
			case 'p':												
				
				command = GETTER;
				break;
				
			case 'w':												
				
				command = SETTER;
				break;
				
			case 'h':												
				
				usage();											// ..the program terminates here.
				return -1;											
				
			case 'v':												
				
				version();											// ..the program terminates here.
				return -1;				
				
			default:
				
				break;
				
		}
	}
	
	
	int n=1;														// A counter for the 'argv' arguments.	
	int m=1;														// A counter for the characters in argv[n].
	char options='\0';												// A 'char' representing options as 1-bit flags.
	
	
	
	/*	OPTIONS FLAGS:
	 All option flags currently MUST preceed all value arguments, for simplicity of design.
	 
	 Valid options are:
	 
	 l:	Display result in 'long' format.
	 s:	Do NOT follow symbolic links.
	 R:	ONLY re-write existing attributes.
	 C:	ONLY create new attributes.
	 
	 */ 
	
	
	while (n<argc && argv[n][0]=='-') {								// for as long as flags are encountered...
		
		m=1;
		
		while (argv[n][m]!='\0') {									// and until the end of this argv string...
			
			switch (argv[n][m]) {
					
					
				case 'l':												
					
					options = options | VERBOSE;				
					break;	
					
				case 's':												
					
					options = options | SYMBOLIC;
					break;
					
				case 'R':												
					
					options = options | REPLACE;
					break;
					
				case 'C':												
					
					options = options | CREATE;
					break;
					
				default:
					
					// An unknown command or option results in help display.
					if (command == LISTER || n>1 ) usage();
					break;
					
			}														// the end of the switch between option flags.
			
			m++;
			
		}															// the character loop ('m' counter) closes.
		
		n++;
		
	}																// the argv loop ('n' counter) closes.
	
	
	int keyPosition=0;
	int valPosition=0;
	int result=0;
	
	
	while ( n<argc ) {												// The value of 'n' is retained from previous loop.
		
		
		if ( command == LISTER ) 
			result = displayXattrKeys(argv[n], options);
		else if (keyPosition == 0) keyPosition=n;
		else switch (command) {
			case GETTER:
				result=result | displayXattrValue(argv[n], argv[keyPosition], options);
				break;
			case SETTER:
				result=result | setXattrValue(argv[n], argv[keyPosition], argv[valPosition], options);
				break;
			case DELETE:
				result=result | deleteXattr(argv[n], argv[keyPosition], options);
				break;
			default:
				break;
		}
		
		
		n++;	
		
	}																	// the argv loop ('n' counter) closes.
	
	
	if (result<0 && command!=HELP) {									// if a problem has arisen...
		
//		giveHelp();				
		return -1;														// ..the program terminates here.
		
	}
	
	return 0;
	
}
