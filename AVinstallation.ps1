function Select-Proxy ()
{
$h=hostname
$ret=""
$prx1 = "10.81.10.66"
$prx2 = "10.81.18.66"
$out1 = Test-NetConnection $prx1
$out2 = Test-NetConnection $prx2
$st1=($out1).PingReplyDetails.Status
$st2=($out2).PingReplyDetails.Status
$rtt1=($out1).PingReplyDetails.RoundtripTime    
$rtt2=($out2).PingReplyDetails.RoundtripTime    

if ($st1 -eq "Success" -and $st2 -eq "Success")
{
    #Write-Host "both Success"
    if ($rtt1 -le $rtt2)
    {
       $ret=$prx1 
    }
    else
    {
       $ret=$prx2
    }

}
elseif ($st1 -eq "Success" -and $st2 -ne "Success")
{
    Write-Host "$prx1 is success."
    $ret=$prx1
}
elseif ($st1 -ne "Success" -and $st2 -eq "Success")
{
    Write-Host "$prx2 is success."
    $ret=$prx2
}
Write-Host "Proxy on $h : $ret"
$ret
}

function CreateTempDir ()
{
    $test_temp={Test-Path -Path C:\temp}
    if ($test_temp)
    {
        Write-Host "Creating C:\temp" -ForegroundColor DarkCyan
        New-Item -Path c:\temp -ItemType Directory
    }
}

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
$out = Test-NetConnection -cn $Comp WINRM -ErrorAction SilentlyContinue| Select-Object ComputerName,RemotePort,PingSucceeded,TcpTestSucceeded  
$TcpTestSucceeded = $out.TcpTestSucceeded

if(($TcpTestSucceeded))
{
     
# New powershell session 
$session = New-PSSession -ComputerName $Comp -ErrorAction SilentlyContinue

If ($session.State -eq 'Opened')
    {
    $test_path_s={Test-Path -Path "$env:ProgramFiles\Microsoft Security Client\MpProvider"}
    $test_path=Invoke-Command -session $session -scriptblock $test_path_s
    $remote_proxy=Invoke-Command -Session $session -ScriptBlock ${Function:Select-Proxy}
    if(!($test_path))
            {
                Write-Host "Antivirus is not installed on $comp! Installing.." -ForegroundColor Red
                Invoke-Command -Session $session -ScriptBlock {C:\windows\System32\bitsadmin.exe /Util /SetIEProxy NETWORKSERVICE Manual_proxy http://$($using:remote_proxy):3128 "*.statoilfuelretail.com;10.*"}
                Invoke-Command -Session $session -ScriptBlock {C:\windows\System32\bitsadmin.exe /Util /SetIEProxy LOCALSYSTEM Manual_proxy http://$($using:remote_proxy):3128 "*.statoilfuelretail.com;10.*"}
                Invoke-Command -Session $session -ScriptBlock ${Function:CreateTempDir}
                Invoke-Command -Session $session -ScriptBlock {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/poorleno1/scep_config/master/EPAMPolicy.xml' -OutFile "c:\\temp\\EPAMPolicy.xml" -Proxy "http:\\$($using:remote_proxy):3128"}
                Invoke-Command -Session $session -ScriptBlock {Invoke-WebRequest -Uri 'http://wsus.ds.download.windowsupdate.com/c/msdownload/update/software/crup/2017/01/scepinstall_2c54f8168cc9d05422cde174e771147d527c92ba.exe' -OutFile "c:\\temp\\scepinstall.exe" -Proxy "http:\\$($using:remote_proxy):3128"}
                Invoke-Command -Session $session -ScriptBlock  {
                                                            & { 
                                                                $proc = Start-Process "c:\temp\scepinstall.exe" -ArgumentList "/s /q /NoSigsUpdateAtInitialExp /policy c:\temp\EPAMPolicy.xml" -PassThru
                                                                $handle = $proc.Handle # cache proc.Handle http://stackoverflow.com/a/23797762/1479211
                                                                $proc.WaitForExit();
                                                            }
                                                        }

            }
            else
            {
                Write-Host "Folder exists. Trying to import module on $comp." -ForegroundColor DarkCyan
                $ImportMod = {Import-Module “$env:ProgramFiles\Microsoft Security Client\MpProvider”} 
                # Display informations 
                $AntiSpy = {Get-MProtComputerStatus | Select -Expand AntispywareEnabled}  
                $AntiSpyLastUp = {Get-MProtComputerStatus | Select -Expand AntispywareSignatureLastUpdated} 
                $AntiVir = {Get-MProtComputerStatus | Select -Expand AntivirusEnabled} 
                $AntiVirLastUp = {Get-MProtComputerStatus | Select -Expand AntivirusSignatureLastUpdated} 
                #$AntiVirLastUp = {(Get-MProtComputerStatus | Select -Expand AntivirusSignatureLastUpdated).ToString("yyyy-MM-dd hh:mm")} 
 
                $Imp = Invoke-Command -session $session -scriptblock $ImportMod 
                $spy = Invoke-Command -session $session -scriptblock $AntiSpy 
                $spyUp = Invoke-Command -session $session -scriptblock $AntiSpyLastUp 
                $vir = Invoke-Command -session $session -scriptblock $AntiVir 
                $virUp = Invoke-Command -session $session -scriptblock $AntiVirLastUp
                
                if (!($spyUp))
                {
                Write-Host "Antivirus was never updated." -ForegroundColor Red
                }
                else
                {

                $currdate=get-date
                $timespanday=(New-TimeSpan -Start $spyUp -End $currdate).Days
                $timespanhour=(New-TimeSpan -Start $spyUp -End $currdate).Hours
                

                Write-Host "Antivirus was updated $spyUp" -ForegroundColor DarkCyan
                Write-Host "Difference on $Comp is $timespanday day(s) and $timespanhour hour(s)." -ForegroundColor DarkCyan
                }
                
                #if ($timespanday -gt 0 -and $timespanhour -gt 4)
                #{
                Write-Host "Setting up proxy" -ForegroundColor Cyan
                Invoke-Command -Session $session -ScriptBlock {C:\windows\System32\bitsadmin.exe /Util /SetIEProxy NETWORKSERVICE Manual_proxy http://$($using:remote_proxy):3128 "*.statoilfuelretail.com;10.*"}
                Invoke-Command -Session $session -ScriptBlock {C:\windows\System32\bitsadmin.exe /Util /SetIEProxy LOCALSYSTEM Manual_proxy http://$($using:remote_proxy):3128 "*.statoilfuelretail.com;10.*"} 
                #}

                if(($session.Id))
                {
                    #Write-Host "Removing session."
                    Remove-PSSession -id $session.Id
                }
            }
   }
   else
   {
    Write-Host "Cannot connect to $comp."
   }
} 
else
{
    Write-Host "TCP port is closed on $comp."
}
} 
 
# sort the table 
#$tab = $tab | Sort-Object "Status of AntiSpyware" 
 
# Add to the body for mail 
#$body = $tab | ConvertTo-HTML -head $a 

#$body


# And send mail 
#send-mailmessage -to "jarekole@circlekeurope.com" -from "jarekole@circlekeurope.com" -subject "EndPoint Protection Status for AD Computers" -body ($body | out-string) -BodyAsHTML -SmtpServer "relay.statoilfuelretail.com" 