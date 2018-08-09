#REQUIRES -Version 2.0  
  
<#  
.SYNOPSIS   
    Check the client status of End Point Protection for AD Computers  
  
.DESCRIPTION  
    Create a schedule task to run daily this script. It will retrieve informations about End Point Protection for AD Computers and send the result by email. 
  
.NOTES    
    NAME: Check_EPM_Status.ps1  
    AUTHOR: PRIGENT Nicolas [www.get-cmd.com]  
    v1.0 - 06/28/2014 - N.PRIGENT : Creation 
  
.LINK   
    Script posted over : www.get-cmd.com  
  
.EXAMPLE   
    Just run ./Check_EPM_Status.ps1  
    If you don't have EPM on a computer, errors will appear in the powershell console. 
#>  
 
# Variables : Modify this query for a specific OU 
 
#$ADComputers = Get-ADComputer -Filter 'ObjectClass -eq "Computer"'  -SearchBase "CN=jdecli020d,OU=Computers,OU=OCLoud,DC=statoilfuelretail,DC=com" | select -ExpandProperty DNsHostname
#$ADComputers = Get-ADComputer -Filter 'ObjectClass -eq "Computer"'  -SearchBase "OU=Computers,OU=OCLoud,DC=statoilfuelretail,DC=com" | select -ExpandProperty DNsHostname
$ADComputers = Get-ADComputer -Filter 'ObjectClass -eq "Computer" -and operatingSystem -like "*Windows*"'  -SearchBase "OU=Computers,OU=OCLoud,DC=statoilfuelretail,DC=com" | select -ExpandProperty DNsHostname
$tab = @() 
 
### 
$a = @' 
<!--mce:0--> 
'@ 
### 
 
# for each computer, get the DNS Host Name 
 
foreach ($Comp in $ADComputers) { 
 
# Reset variables 
 
$objet = new-object Psobject 

$out = Test-NetConnection -cn $Comp WINRM | Select-Object ComputerName,RemotePort,PingSucceeded,TcpTestSucceeded  

$TcpTestSucceeded = $out.TcpTestSucceeded

if(($TcpTestSucceeded))
{
     
# New powershell session 
$session = New-PSSession -ComputerName $Comp 

$test_path_s={Test-Path -Path "$env:ProgramFiles\Microsoft Security Client\MpProvider"}
$test_path=Invoke-Command -session $session -scriptblock $test_path_s

if(!($test_path))
        {
            Write-Host "Folder does not exists on $comp!"
        }
        else
        {
            Write-Host "Folder exists. Trying to import module on $comp."
            $ImportMod = {Import-Module “$env:ProgramFiles\Microsoft Security Client\MpProvider”} 
 
            # Display informations 
 
            $AntiSpy = {Get-MProtComputerStatus | Select -Expand AntispywareEnabled}  
            $AntiSpyLastUp = {Get-MProtComputerStatus | Select -Expand AntispywareSignatureLastUpdated} 
            $AntiVir = {Get-MProtComputerStatus | Select -Expand AntivirusEnabled} 
            $AntiVirLastUp = {Get-MProtComputerStatus | Select -Expand AntivirusSignatureLastUpdated} 
 
            $Imp = Invoke-Command -session $session -scriptblock $ImportMod 
            $spy = Invoke-Command -session $session -scriptblock $AntiSpy 
            $spyUp = Invoke-Command -session $session -scriptblock $AntiSpyLastUp 
            $vir = Invoke-Command -session $session -scriptblock $AntiVir 
            $virUp = Invoke-Command -session $session -scriptblock $AntiVirLastUp 
 
            $objet | Add-member -Name "Server name" -Membertype "Noteproperty" -Value $Comp 
            $objet | Add-member -Name "Status of AntiSpyware" -Membertype "Noteproperty" -Value $spy 
            $objet | Add-member -Name "Last updated AntiSpyware Signature" -Membertype "Noteproperty" -Value $spyUp 
            $objet | Add-member -Name "Status of AntiVirus" -Membertype "Noteproperty" -Value $vir 
            $objet | Add-member -Name "Last updated AntiVirus Signature" -Membertype "Noteproperty" -Value $virUp 
            $tab += $objet 
            
        }


    # Import module EPM 
 

    if(($session.Id))
    {
        Remove-PSSession -id $session.Id
    }


}




} 
 
# sort the table 
$tab = $tab | Sort-Object "Server Name" 
 
# Add to the body for mail 
$body = $tab | ConvertTo-HTML -head $a 

#$body


# And send mail 
send-mailmessage -to "jarekole@circlekeurope.com" -from "jarekole@circlekeurope.com" -subject "EndPoint Protection Status for AD Computers" -body ($body | out-string) -BodyAsHTML -SmtpServer "relay.statoilfuelretail.com" 