<# Use ldifde to clone WMI filters from one domain to another. This does the export part. #>

param(
    [string]$ExportFile="wmi.txt",

    [string]$DC="dc1.ad.contoso.com",

    [string]$SourceDN="DC=ad,DC=contoso,DC=com",
    [string]$TargetDN="DC=tstad,DC=contoso,DC=com"
)

<# Export OUs from source domain. #>
ldifde -f $ExportFile -s $DC -r "(objectclass=msWMI-Som)" -t 636 -c $SourceDN $TargetDN -l dn,objectClass,cn,distinguishedName,instanceType,showInAdvancedViewOnly,name,objectCategory,msWMI-Author,msWMI-ChangeDate,msWMI-CreationDate,msWMI-ID,msWMI-Name,msWMI-Parm1,msWMI-Parm2
