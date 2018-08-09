$gr=@("cg_s_wincli001p_prod_adm","cg_s_wincli002p_prod_adm","cg_s_wincli003p_prod_adm","cg_s_wincli004p_prod_adm","cg_s_wincli006p_prod_adm","cg_s_wincli007p_prod_adm","cg_s_wincli009p_prod_adm")

foreach ($g in $gr) {
    $mem = get-adgroupmember $g | % { $_.name}
    Write-host $g":"$mem
}


$gr1=@("JDE_CNC","DB_Admin","soa_admin","soa_developer","WC_Admin","IDM_Admin","IDM_Developer","WC_Developer")
foreach ($g in $gr1) {
    $mem = get-adgroupmember $g | % { $_.name + ","}
    Write-host $g":"$mem
}
