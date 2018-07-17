#Based on flat text file with group names script gets a member of group where users can be in two differnt AD domains

foreach($line in Get-Content "C:\temp\jarek\groups.txt" ) {
    if($line -match $regex){
        write-host "group:" $line
        Get-ADGroupMember "$line" |foreach {
        $usr = $_.Samaccountname
        $empty = ""
            try
            {
                #creating array
                $arr = @(Get-aduser $_.Samaccountname -properties enabled,EmployeeID | where {$_.enabled -eq $True} | select name,samaccountname,EmployeeID)
                #adding new column
                $arr | Add-Member -MemberType NoteProperty "TopazADGroup" -Value "$line"
                $arr | Export-Csv -Path c:\temp\jarek\user_list.csv -Delimiter ";" -NoClobber -Append
            }
            catch
            {
                $out = ("""{0}"";""{1}"";""{2}"";""{3}""" -f $empty,$usr,$empty,$line)
                Out-File -filepath  c:\temp\jarek\user_list.txt -InputObject $out -Append
            }
        }
    }
}

