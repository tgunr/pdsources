//
//	gcc -o dacauth dacauthorize.c -framework CoreFoundation -framework Security
//

#include <CoreFoundation/CoreFoundation.h>
#include <Security/AuthorizationDB.h>
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

char copy_install_bin[] = "/bin/cp";
char* copy_install_args[] = { "-R", "DACALDriver.kext", "/System/Library/Extensions/", NULL };

char copy_remove_bin[] = "/bin/rm";
char* copy_remove_args[] = { "-R", "/System/Library/Extensions/DACALDriver.kext", NULL };

char kext_unload_bin[] = "/sbin/kextunload";
char* kext_unload_args[] = { "/System/Library/Extensions/DACALDriver.kext", NULL };

char kext_load_bin[] = "/sbin/kextload";
char* kext_load_args[] = { "/System/Library/Extensions/DACALDriver.kext", NULL };

int doPrivledged( char myToolPath[], char *myArguments[] )
{
 
    OSStatus myStatus;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
    AuthorizationRef myAuthorizationRef;
 
    myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
    if (myStatus != errAuthorizationSuccess)
        return myStatus;
 
    do 
    {
        {
            AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
            AuthorizationRights myRights = {1, &myItems};
 
            myFlags = kAuthorizationFlagDefaults |
                    kAuthorizationFlagInteractionAllowed |
                    kAuthorizationFlagPreAuthorize |
                    kAuthorizationFlagExtendRights;
            myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, NULL, myFlags, NULL );
        }
 
        if (myStatus != errAuthorizationSuccess) break;
 
        {
            FILE *myCommunicationsPipe = NULL;
            char myReadBuffer[128];
 
            myFlags = kAuthorizationFlagDefaults;
            myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, myToolPath, myFlags, myArguments, &myCommunicationsPipe);
 
            if (myStatus == errAuthorizationSuccess)
                for(;;)
                {
                    int bytesRead = read (fileno (myCommunicationsPipe),
                            myReadBuffer, sizeof (myReadBuffer));
                    if (bytesRead < 1) break;
                write (fileno (stdout), myReadBuffer, bytesRead);
                }
        }
    } while (0);
 
    AuthorizationFree(myAuthorizationRef, kAuthorizationFlagDefaults);
 
    if (myStatus) printf("DACAuthorize Error: %ld Tool:%s\n", myStatus, myToolPath );
    return myStatus;
}

int	runKextUnload()
	{ return doPrivledged( kext_unload_bin, kext_unload_args ); }

int	runKextLoad()
	{ return doPrivledged( kext_load_bin, kext_load_args ); }

int	runKextRemove()
	{ return doPrivledged( copy_remove_bin, copy_remove_args ); }

int	runKextInstall( char* originalPath )
{ 
	if( originalPath != NULL ) copy_install_args[1] = originalPath;
	return doPrivledged( copy_install_bin, copy_install_args );
}

int	runRemoveDriver()
{
	int		outErr = -1;

	outErr = runKextUnload();
	sleep( 2 );
	outErr = runKextRemove();

	return outErr;
}

int runInstallDriver( char* originalPath )
{
	int		outErr = -1;
	
	outErr = runKextInstall( originalPath );
	if( outErr == 0 ) outErr = runKextLoad();

	return outErr;
}

int main(int argc, char* argv[])
{
	int		outValue = 1;
	char*	commandString = NULL;
	char*	originalPath = NULL;
	
	if( argc > 1 ) {
		commandString = argv[1];
		switch( commandString[1] ) {
			case 'i':
				if( argc > 2 ) originalPath = argv[2];
				outValue = runInstallDriver( originalPath );
				break;
			case 'r':
				outValue = runRemoveDriver();
				break;
			case 'l':
				outValue = runKextLoad();
				break;
			case 'u':
				outValue = runKextUnload();
				break;
			default:
				break;
		}	
	}
	return outValue;
}
