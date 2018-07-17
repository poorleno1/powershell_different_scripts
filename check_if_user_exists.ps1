$UserList = @("A-EXT-WACHA","A-EXT-ADAGOL","A-EXT-RAFGOL","A-EXT-PIOBU","A-EXT-JANUMAR","A-EXT-ARTJAR","A-EXT-DARIMIL","A-EXT-MICRYB","A-EXT-SLASTR","A-EXT-MARJOZ","A-EXT-TOMSLE","A-EXT-RAFJAN","A-EXT-PIOZAW","A-EXT-AK133","A-EXT-PIASI","A-EXT-TOMLAH","A-EXT-GRZSTR","A-EXT-SZYMI","A-EXT-PAWPIE")
foreach ($u in $UserList) {
    try {
        $ADUser = Get-ADUser -Identity $u -ErrorAction Stop
    }
    catch {
        if ($_ -like "*Cannot find an object with identity: '$u'*") {
            "User '$u' does not exist."
        }
        else {
            "An error occurred: $_"
        }
        continue
    }
    "User '$($ADUser.SamAccountName)' exists. Created in OU: $($ADUser.DistinguishedName) "
    # Do stuff with $Result
}