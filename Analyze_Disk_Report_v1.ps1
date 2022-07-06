########################################################################################

# Script        :   The script will create a disk report in HTML format. It needs a list of machines/server defined in the computers variable to target the machines 
# we want the report for
# Author        :   Anshul Awasthi (anshulawasthi1313@gmail.com)  

########################################################################################

Param (  
$computers = (Get-Content  "C:\Users\Aawast1\Documents\serverlist.txt") 
) 

$Todaydate = (Get-Date).ToString('yyyyMMdd') 
 
$Title="Analyze disk space report to HTML" 
 
#embed a stylesheet in the html header 
$Head = @"
  
<style>
  body {
    font-family: "Arial";
    font-size: 10pt;
    color: #4C607B;
    }
  th, td { 
    border: 1px solid #e57300;
    border-collapse: collapse;
    padding: 5px;
    }
  th {
    font-size: 1.2em;
    text-align: left;
    background-color: #003366;
    color: #ffffff;
    }
  td {
    color: #000000;
    }
  .even { background-color: #ffffff; }
  .odd { background-color: #bfbfbf; }
</style>
<Title>$Title</Title> 
<br> 
"@  
 
#define an array for html fragments 
$fragments=@() 
 
#get the drive data 
$data=Get-WmiObject -Class Win32_logicaldisk -filter "drivetype=3" -computer $computers 
 
#group data by computername 
$groups=$Data | Group-Object -Property SystemName 
 
#this is the graph character 
[string]$g=[char]9608  
 
#create html fragments for each computer 
#iterate through each group object 
         
ForEach ($computer in $groups) { 
     
    $fragments+="<H2>Hostname:: $($computer.Name)</H2>" 
     
    #define a collection of drives from the group object 
    $Drives=$computer.group 
     
    #create an html fragment 
    $html=$drives | Select @{Name="Drive";Expression={$_.DeviceID}}, 
    @{Name="SizeGB";Expression={$_.Size/1GB  -as [int]}}, 
    @{Name="UsedGB";Expression={"{0:N2}" -f (($_.Size - $_.Freespace)/1GB) }}, 
    @{Name="FreeGB";Expression={"{0:N2}" -f ($_.FreeSpace/1GB) }}, 
    @{Name="Usage";Expression={ 
      $UsedPer= (($_.Size - $_.Freespace)/$_.Size)*100 
      $UsedGraph=$g * ($UsedPer/2) 
      $FreeGraph=$g* ((100-$UsedPer)/2) 
      #I'm using place holders for the < and > characters 
      "xopenFont color=Redxclose{0}xopen/FontxclosexopenFont Color=Greenxclose{1}xopen/fontxclose" -f $usedGraph,$FreeGraph 
    }}| ConvertTo-Html -Fragment    
     
    #replace the tag place holders. It is a hack but it works. 
    $html=$html -replace "xopen","<" 
    $html=$html -replace "xclose",">" 
     
    #add to fragments 
    $Fragments+=$html 
     
    #insert a return between each computer 
    $fragments+="<br>" 
     
$footer=("<br>With Avg Percentage CPU Utilization: {0}%" -f (Get-CimInstance -ComputerName $computer.Name -Class win32_processor -ErrorAction `
Stop|Measure-Object -Property LoadPercentage -Average|Select-Object Average).Average) 

$fragments+=$footer

} #foreach computer 
 
#add a footer 

$footer1=("<br><I>Report run {0} by {1}\{2}<I>" -f (Get-Date -displayhint date),$env:userdomain,$env:username) 


$fragments+=$footer1 
 
#write the result to a file 
ConvertTo-Html -head $head -body $fragments  | Out-File "C:\Users\Aawast1\Documents\drivereport_$Todaydate.htm"
