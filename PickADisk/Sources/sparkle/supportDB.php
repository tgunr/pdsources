<?php
// $Id: profileDB.php 2 2006-06-08 19:33:50Z tph $
// $HeadURL: http://sparkleplus.googlecode.com/svn/trunk/profileDB.php $
// TryOpenDb and CloseDb - Open and close the database.
// Change the username, password, and database to the correct values for your database
	$DbLink = FALSE;
	$DbError = "";

function TryOpenDb()
{
	global $DbLink;
	global $DbError;

	global $db_host;
	global $db_user;
	global $db_password;
	global $db_name;

	/* Connecting, selecting database */
	$DbLink = mysql_connect($db_host, $db_user, $db_password);

	if (!$DbLink)
	{
		$DbError = mysql_error();
		return FALSE;
	}

	if (!mysql_select_db($db_name))
	{
		$DbError = mysql_error();
		CloseDb();
		return FALSE;
	}

	mysql_query("BEGIN");
	return $DbLink;
}

function CloseDb()
{
	global $DbLink;

	if ($DbLink)
	{
		mysql_query("COMMIT");
		mysql_close($DbLink);
		$DbLink = FALSE;
	}
}

function abortAndExit()
{
	global $DbLink;
	$db_host		= "mysql.polymicrosystems.com";
	print "Aborting database communication: " . mysql_error();
	if ($DBLink) {
		mysql_query("ROLLBACK");
		mysql_close($DbLink);
		$DbLink = FALSE;
	}
	exit();
}

function returnMacAddress() {
	// This code is under the GNU Public Licence
	// Written by michael_stankiewicz {don't spam} at yahoo {no spam} dot com
	// Tested only on linux, please report bugs
	
	// WARNING: the commands 'which' and 'arp' should be executable
	// by the apache user; on most linux boxes the default configuration
	// should work fine
	
	// Get the arp executable path
	$location = `which arp`;
	// Execute the arp command and store the output in $arpTable
	$arpTable = `$location`;
	// Split the output so every line is an entry of the $arpSplitted array
	$arpSplitted = split("\n",$arpTable);
	// Get the remote ip address (the ip address of the client, the browser)
	$remoteIp = $GLOBALS['REMOTE_ADDR'];
	// Cicle the array to find the match with the remote ip address
	foreach ($arpSplitted as $value) {
		// Split every arp line, this is done in case the format of the arp
		// command output is a bit different than expected
		$valueSplitted = split(" ",$value);
		foreach ($valueSplitted as $spLine) {
			if (preg_match("/$remoteIp/",$spLine)) {
				$ipFound = true;
			}
			// The ip address has been found, now rescan all the string
			// to get the mac address
			if ($ipFound) {
				// Rescan all the string, in case the mac address, in the string
				// returned by arp, comes before the ip address
				// (you know, Murphy's laws)
				reset($valueSplitted);
				foreach ($valueSplitted as $spLine) {
					if (preg_match("/[0-9a-f][0-9a-f][:-]".
					"[0-9a-f][0-9a-f][:-]".
					"[0-9a-f][0-9a-f][:-]".
					"[0-9a-f][0-9a-f][:-]".
					"[0-9a-f][0-9a-f][:-]".
					"[0-9a-f][0-9a-f]/i",$spLine)) {
						return $spLine;
					}
				}
			}
			$ipFound = false;
		}
	}
	return false;
}


?>
