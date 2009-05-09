<?php

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

echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 TRANSITIONAL//EN\">
<html>
	<head>
		<title>PickADisk Sparkle Reportcard</title>
		<link href=\"support/css/report.css\" type=\"text/css\" rel=\"stylesheet\" media=\"all\">
	</head>
	<body>
";

require("supportConfig.php");

/* Connecting, selecting database */

$DbLink = mysql_connect($db_host, $db_user, $db_password);
if (!mysql_select_db($db_name)) {
	$DbError = mysql_error();
	CloseDb();
	return FALSE;
}

echo "<table>\n";

mysql_query("BEGIN");
$query = "CALL create_combinedReport";
$result = mysql_query($query) or die('Query failed: ' . mysql_error());

$query = "select column_name from information_schema.columns where table_name = 'combinedReport'";
$result = mysql_query($query) or die('Query failed: ' . mysql_error());

// Printing results in HTML
echo "\t<tr id=\"colname\">\n";
$colID = 1;
while ($line = mysql_fetch_array($result, MYSQL_ASSOC)) {
    foreach ($line as $col_value) {
        echo "\t\t<td class=\"colname\" id=\"colname$colID\">$col_value</td>\n";
        $colID += 1;
    }
}
    echo "\t</tr>\n";

// Record the report
$report_date = strftime("%Y-%m-%d %H:%M:%S");
    $query = "SELECT * FROM combinedReport ORDER BY id DESC";
if (1) {
	print "$query<br/>\n";
}

$result = mysql_query($query) or die('Query failed: ' . mysql_error());

while ($line = mysql_fetch_array($result, MYSQL_ASSOC)) {
    echo "\t<tr class=\"row\">\n";
    foreach ($line as $col_value) {
        echo "\t\t<td class=\"row\">$col_value</td>\n";
    }
    echo "\t</tr>\n";
}
echo "</table>\n";

// Free resultset
mysql_free_result($result);

CloseDB();
print "</body>\n</html>";


?>
