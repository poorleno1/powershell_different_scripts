$root = 'DC=corp,DC=contoso,DC=com'
$new = "Groups"


#Creating OUs in AD

New-OU $new $root
New-OU 'Common' "OU=Groups,$root"
New-OU 'MARKET_IRL_Common' "OU=Common,OU=Groups,$root"
New-OU 'MARKET_IRL_Org' "OU=Common,OU=Groups,$root"
New-OU 'MARKET_IRL_Dept' "OU=Common,OU=Groups,$root"

#Creating groups

Import-Csv -Path C:\users\vagrant\Documents\input.csv |foreach {
$ou = "OU=MARKET_"+($_.path).split("\")[2]+",OU=Common,OU=Groups,"+$root

New-MyADgroup $_.path $_.modify $ou "Modify"
New-MyADgroup $_.path $_.read $ou "Read"
}

function New-OU {
    param
    (
        [Parameter(Mandatory=$true)]
        $newOU,

        # Param2 help description
        [Parameter(Mandatory=$false)]
        $parentOU
    )


if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq 'OU=$newOU,$parentOU'") {
      Write-Host "$newOU already exists in $parentOU."
    } else {
      Write-Host "Creating new organizational unit: $newOU in $parentOU."
      New-ADOrganizationalUnit -Name "$newOU" -Path "$parentOU" -ProtectedFromAccidentalDeletion $false
    }
}


function New-MyADgroup ($path, $name,$OUPath,$perm)
{
    if (Get-ADgroup -LDAPFilter "(Samaccountname=$name)") {
      Write-Host "Group $name already exists in $OUPath."
    } else {
      Write-host "Creating new group: $name in $OUPath with details $path"
      New-ADGroup -Path $OUPath -GroupScope DomainLocal -Name $name -Description "$perm group for $path" -OtherAttributes @{'info'="Created as part of File Migration, PM: Piotr Zawistowki, Change:"}
    }
}
