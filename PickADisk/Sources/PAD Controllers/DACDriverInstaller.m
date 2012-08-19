//
//  DACDriverInstaller.m
//  PickADisk
//
//  Copyright 2008 PolyMicro Systems. All rights reserved.
//

#import "DACDriverInstaller.h"

CFStringRef		dac_installer_bin = CFSTR("dacauth");

CFStringRef		dac_installer_install = CFSTR("-i");
CFStringRef		dac_installer_remove = CFSTR("-r");
CFStringRef		dac_installer_load = CFSTR("-l");
CFStringRef		dac_installer_unload = CFSTR("-u");

CFStringRef		dac_installer_item_name = CFSTR("DACALDriver.kext");
CFStringRef		dac_installer_item_installpath = CFSTR("/System/Library/Extensions/DACALDriver.kext");

CFStringRef CFBundleRunPrivledgedInternalExecutable( CFAllocatorRef inAllocator, CFBundleRef toolBundle, CFStringRef toolName, CFArrayRef tooArgs, OSStatus* outError );
CFStringRef CFBundleRunPrivledgedInternalExecutable( CFAllocatorRef inAllocator, CFBundleRef toolBundle, CFStringRef toolName, CFArrayRef tooArgs, OSStatus* outError )
{
	
    OSStatus	myStatus;
	Boolean		myToolFound = FALSE;
	CFURLRef	myToolURL = NULL;
	UInt8		myToolPath[4096];
	char*		myArguments[16] = { NULL };
	int			index = 0;
	int			count = 0;

	CFMutableStringRef	myCFOut = NULL;
	
    AuthorizationFlags	myFlags = kAuthorizationFlagDefaults;
    AuthorizationRef	myAuthorizationRef;
	
    myStatus = AuthorizationCreate( NULL, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef );
    if( myStatus != errAuthorizationSuccess )
        goto EXIT;
	
	if( tooArgs != NULL ) {		
		count = CFArrayGetCount( tooArgs );
		if( count > 16 ) count = 15;
		for( index=0; index < count; index++ )
			myArguments[index] = CFStringCreateCString( CFArrayGetValueAtIndex(tooArgs, index), kCFStringEncodingUTF8 );
	}
	
	myArguments[index] = (char*)NULL;
	
	myStatus = kCFURLImproperArgumentsError;
	myToolURL = CFBundleCopyAuxiliaryExecutableURL( toolBundle, toolName );
	if( myToolURL == NULL ) goto EXIT;
		
	myToolFound = CFURLGetFileSystemRepresentation( myToolURL, TRUE, (UInt8*)myToolPath, 4096 );
	if( !myToolFound ) goto EXIT;
	
    do 
    {
        {
            AuthorizationItem myItems = { kAuthorizationRightExecute, 0, NULL, 0 };
            AuthorizationRights myRights = { 1, &myItems };
			
            myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed ;
            myStatus = AuthorizationCopyRights( myAuthorizationRef, &myRights, NULL, myFlags, NULL );
        }
		
        if( myStatus != errAuthorizationSuccess ) break;
		
        {
            FILE*	myCommunicationsPipe = NULL;
            char	myReadBuffer[128];
			
			myCFOut = CFStringCreateMutable( inAllocator, 4096 );
			
            myFlags = kAuthorizationFlagDefaults;
            myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, (const char*)myToolPath, myFlags, myArguments, &myCommunicationsPipe);
			
            if (myStatus == errAuthorizationSuccess)
                for(;;)
                {
                    int bytesRead = read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
                    if (bytesRead < 1) break;
					
					myReadBuffer[ bytesRead ] = 0;
					CFStringAppendCString( myCFOut, myReadBuffer, kCFStringEncodingUTF8 );
                }
        }
    } while(0);
	
EXIT:
	
	if( myCFOut ) CFShow( myCFOut );
    if( myStatus ) printf( "runPrivledgedInternalTool Error: %ld\n", myStatus );

    AuthorizationFree( myAuthorizationRef, kAuthorizationFlagDefaults );

	//if( myToolPath ) free( myToolPath );
	//if( myArguments ) free( myArguments );
	if( myToolURL ) CFRelease( myToolURL );
	
	if( outError != NULL ) *outError = myStatus;
    return myCFOut;
}

CFStringRef		DACALDriverInstallerTool(CFAllocatorRef inAllocator, CFBundleRef fromBundle, CFArrayRef callParam, OSStatus* outStatus );
CFStringRef		DACALDriverInstallerTool(CFAllocatorRef inAllocator, CFBundleRef fromBundle, CFArrayRef callParam, OSStatus* outStatus )
{
	OSStatus	outError = kCFURLImproperArgumentsError;
	CFStringRef	runResult = NULL;
	
	CFShow(callParam);
	
	runResult = CFBundleRunPrivledgedInternalExecutable( inAllocator, fromBundle, dac_installer_bin, callParam, &outError );
	
	if( outStatus != NULL ) *outStatus = outError;
	return runResult;
}


CFStringRef		DACALDriverInstall(CFAllocatorRef inAllocator, CFBundleRef fromBundle, OSStatus* outStatus )
{
	OSStatus	outError = kCFURLImproperArgumentsError;
	CFURLRef	itemURL = NULL;
	char		itemPathChars[4096];
	CFStringRef	itemPath = NULL;
	CFArrayRef	itemParam = nil;
	const void*	paramArray[] = { CFSTR("-i"), nil };
	Boolean		itemFound = FALSE;
	CFStringRef	runResult = NULL;
	
	itemURL = CFBundleCopyAuxiliaryExecutableURL( fromBundle, dac_installer_item_name );
	if( itemURL == NULL ) goto EXIT;
	
	itemFound = CFURLGetFileSystemRepresentation( itemURL, TRUE, (UInt8*)itemPathChars, 4096 );
	if( !itemFound ) goto EXIT;
	
	itemPath = CFStringCreateWithCString( inAllocator, itemPathChars, kCFStringEncodingUTF8 );
	if( !itemPath ) goto EXIT;
	
	paramArray[1] = itemPath;
	
	itemParam = CFArrayCreate( inAllocator, paramArray, 2, &kCFTypeArrayCallBacks );
	if( itemParam == NULL ) goto EXIT;
	
	runResult = DACALDriverInstallerTool( inAllocator, fromBundle, itemParam, &outError );
	
EXIT:
	if( itemURL != NULL ) CFRelease( itemURL );
	if( itemPath != NULL ) CFRelease( itemPath );
	if( itemParam != nil ) CFRelease( itemParam );
	
	if( outStatus != NULL ) *outStatus = outError;
	return runResult;
}

CFStringRef		DACALDriverUnInstall(CFAllocatorRef inAllocator, CFBundleRef fromBundle, OSStatus* outStatus );
CFStringRef		DACALDriverUnInstall(CFAllocatorRef inAllocator, CFBundleRef fromBundle, OSStatus* outStatus )
{
	OSStatus	outError = kCFURLImproperArgumentsError;
	CFArrayRef	itemParam = nil;
	const void*	paramArray[] = { CFSTR("-r") };
	CFStringRef	runResult = NULL;
	
	itemParam = CFArrayCreate( inAllocator, paramArray, 1, &kCFTypeArrayCallBacks );
	if( itemParam != NULL )	
		runResult = DACALDriverInstallerTool( inAllocator, fromBundle, itemParam, &outError );
	
	if( itemParam != nil ) CFRelease( itemParam );
	
	if( outStatus != NULL ) *outStatus = outError;
	return runResult;
}



@implementation DACDriverInstaller
static DACDriverInstaller*	DACDriverInstaller_shared = nil;

-(IBAction)installKextAction:(id)sender
	{ [[self class] installDACALDriverKext]; }

-(IBAction)uninstallKextAction:(id)sender
	{ [[self class] uninstallDACALDriverKext]; }

-(id)init
{
	if( DACDriverInstaller_shared )
		return (id)DACDriverInstaller_shared;
	
	if( self = [super init] )
	{
		//NSLog(@"DACDriver Installer Created");
		DACDriverInstaller_shared = (DACDriverInstaller*)self;
	}
	return self;
}

+(DACDriverInstaller*)sharedDACInstaller
{
	if( !DACDriverInstaller_shared )
		[[DACDriverInstaller alloc] init];
		
	return (id)DACDriverInstaller_shared;
}

+(OSStatus)installDACALDriverKext
{
	OSStatus		runError = kCFURLImproperArgumentsError;
	CFStringRef		runResult = DACALDriverInstall( kCFAllocatorDefault, CFBundleGetMainBundle(), &runError );
	
	if( runResult != NULL ) CFRelease( runResult );
	
	[[NSUserDefaults standardUserDefaults] setObject:[[NSDate date] description] forKey:@"DACALDriverInstalled"];
	
	return runError;
}

+(OSStatus)uninstallDACALDriverKext
{
	OSStatus		runError = kCFURLImproperArgumentsError;
	CFStringRef		runResult = DACALDriverUnInstall( kCFAllocatorDefault, CFBundleGetMainBundle(), &runError );
	
	if( runResult != NULL ) CFRelease( runResult );
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DACALDriverInstalled"];
	
	return runError;
}

+(BOOL)isDriverKextInstalled
	{ return [[NSWorkspace sharedWorkspace] isFilePackageAtPath:(NSString*)dac_installer_item_installpath]; }	

+(NSString*)versionOfDriverKextLoaded
{
	NSTask*				doTask = [[NSTask alloc] init];
	NSPipe*				outPipe=[[NSPipe alloc] init];
	NSFileHandle*		pipeHandle;
	NSString*			taskStdOut;
	NSString*			subString = nil;
	NSString*			versString = nil;
	
	//[doTask setLaunchPath:@"/bin/sh"];
	//[doTask setArguments:[NSArray arrayWithObjects:@"-c", @"/usr/sbin/kextstat",nil]];
	[doTask setLaunchPath:@"/usr/sbin/kextstat"];
	[doTask setArguments:[NSArray arrayWithObjects:@"-l", @"-b", @"com.polymicrosystems.driver.DACALDriver", nil]];
	//[doTask setArguments:[NSArray arrayWithObjects:@"-c", @"/usr/sbin/kextstat | /usr/bin/grep -i com.polymicrosystems.driver.DACALDriver", nil]];
	//[doTask setArguments:[NSArray arrayWithObjects:@"-c", @"/usr/sbin/kextstat", @"|", @"/usr/bin/grep", @"-i", @"com.polymicrosystems.driver.DACALDriver", nil]];
	//[doTask setArguments:[NSArray arrayWithObjects:@"-c", @"/usr/sbin/kextstat", nil]];
	[doTask setStandardOutput:outPipe];
	pipeHandle = [outPipe fileHandleForReading];
	
	[doTask launch];
	
	taskStdOut = [[NSString alloc] initWithData:[pipeHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
	
	//NSLog(@"Let there be results: %@", taskStdOut);
	
	if( [taskStdOut length] > 0 )
	{
		subString = [taskStdOut substringFromIndex:([taskStdOut rangeOfString:@"("].location+1)];
		if( subString )
			versString = [subString substringToIndex:[subString rangeOfString:@")"].location];
	}
	
	if( versString ) NSLog(@"DACALDriver.kext version %@ loaded.", versString);
	
	[taskStdOut release];
	[outPipe release];
	[doTask release];
	
	return versString;
}

+(NSDate*)dateDriverKextInstalled
{ 
	
	NSString*	dateString = [[NSUserDefaults standardUserDefaults] stringForKey:@"DACALDriverInstalled"];
	NSDate*		outDate = nil;
	
	if( dateString ) outDate = [NSDate dateWithString:dateString];
	
	return outDate;
}








@end



// end








