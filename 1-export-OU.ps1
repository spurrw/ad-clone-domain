<# Use ldifde to clone OU structure from one domain to another. #>

param(
    [string]$ExportFile="OUs.txt",

    [string]$DC="dc1.ad.contoso.com",

    [string]$SourceDN="DC=ad,DC=contoso,DC=com",
    [string]$TargetDN="DC=tstad,DC=contoso,DC=com"
)

<# Export OUs from source domain. #>
ldifde -f $ExportFile -s $DC -r "(objectClass=organizationalUnit)" -t 636 -c $SourceDN $TargetDN -l dn,objectClass,name
