################################################################################################################################################
# Script     :   PowerShell - Connects with CA databases and raise event in case of failed and
#                pending searches.
# Author     :   Awasthi, Anshul (anshulawasthi1313@gmail.com)   

################################################################################################################################################

$SQLDBNames = @(
"Database1"
"Database2"
"Database3"
)

Function fnscom
{
#New-EventLog –LogName Application –Source "DB search Audit" #Run this command first time only
Write-EventLog –LogName Application –Source "DB search Audit" –EntryType $x –EventID $y –Message $z
}


foreach($SQLDBName in $SQLDBNames){

$SQLServer = "C2-CA.qa.testansh.com,63314" # DB instance name eg DBinstancename,portnumber
 
$SqlQuery = "select count (*) from tblIntSearches where StatusID in (10,174) or (StatusID IN (2,6,5) AND RunDate < DATEADD(hour,3,GETDATE()))" # CA database query
# to look for failed and pending searches.

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection 
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security= $True"
  
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand 
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
  
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter 
$SqlAdapter.SelectCommand = $SqlCmd
  
$DataSet = New-Object System.Data.DataSet 
$SqlAdapter.Fill($DataSet)
$SqlConnection.Close()

$Amp_CA = $DataSet.Tables[0].Column1

if ($Amp_CA -gt '0'){

echo "`nFetching pending and failed searches count for $SQLDBName. The count is : $Amp_CA `n"
  $x = "Error"
  $y = "65051"
  $z = "CA search Audit - The CA searches for database `"$SQLDBName`" are either pending, failed or stuck and the total frozen search count is : $Amp_CA. Please login to confirm."
  echo "CA search Audit - The CA searches for database `"$SQLDBName`" are either pending, failed or stuck and the total frozen search count is : $Amp_CA. Please login to confirm."
  fnscom($x,$y,$z)
}
else{
echo "The CA searches are working fine for $SQLDBName. Exiting the script."
}
}
