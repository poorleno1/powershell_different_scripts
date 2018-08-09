#$ADComputers = Get-ADComputer -Filter 'ObjectClass -eq "Computer"'  -SearchBase "CN=CCSFS003P,OU=Computers,OU=OCLoud,DC=statoilfuelretail,DC=com" | select -ExpandProperty DNsHostname
$ADComputers = Get-ADComputer -Filter 'ObjectClass -eq "Computer" -and operatingSystem -like "*Windows*"'  -SearchBase "OU=Computers,OU=OCLoud,DC=statoilfuelretail,DC=com" | select -ExpandProperty DNsHostname
$tab = @() 
$obj1 =@()


foreach ($Comp in $ADComputers) { 
$out = Test-NetConnection -cn $Comp WINRM | Select-Object ComputerName,RemotePort,PingSucceeded,TcpTestSucceeded  

$remoteport = $out.RemotePort
$PingSucceeded = $out.PingSucceeded
$TcpTestSucceeded = $out.TcpTestSucceeded

$properties = @{'Computer'=$Comp;
                'RemotePort'=$out.RemotePort;
                'PingSucceeded'=$out.PingSucceeded;
                'TcpTestSucceeded'=$out.TcpTestSucceeded}


#$objet = [pscustomobject]$properties
$objet = new-object Psobject

$objet | Add-member -Name "ServerName" -Membertype "Noteproperty" -Value $Comp 
$objet | Add-member -Name "RemotePort" -Membertype "Noteproperty" -Value $remoteport 
$objet | Add-member -Name "PingSucceeded" -Membertype "Noteproperty" -Value $PingSucceeded 
$objet | Add-member -Name "TcpTestSucceeded" -Membertype "Noteproperty" -Value $TcpTestSucceeded 
$tab += $objet

}

$tab | select ServerName,RemotePort,PingSucceeded,TcpTestSucceeded | Export-Csv c:\temp\wsman.txt