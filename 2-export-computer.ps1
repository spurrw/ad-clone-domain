<# Exports computers from source domain with ldifde. Sets them all to "disabled" so
they're ready to be imported into the target domain. If you don't disable them
they can't be imported because you aren't setting passwords.

Settings passwords requires connecting to target DC on LDAPS, which doesn't work
if you don't have a CA.

Run this as Domain Admin if you have computers that can't be read by normal computers.
#>

param(
    [string]$ExportFile="computers.txt",

    [string]$DC="dc1.ad.contoso.com",

    [string]$SourceDN="DC=ad,DC=contoso,DC=com",
    [string]$TargetDN="DC=tstad,DC=contoso,DC=com"
)

If (Test-Path $ExportFile) {
    Remove-Item $ExportFile
}

Write-Host "Exporting computers to file..."
$ExportFileTemp = $ExportFile + ".tmp"
ldifde -f $ExportFileTemp -s $DC -r "(&(objectClass=computer)(!(objectClass=msDS-GroupManagedServiceAccount)))" -t 636 -c $SourceDN $TargetDN -l dn,objectClass,description,name,userAccountControl,msDS-SupportedEncryptionTypes,samAccountName

Write-Host "Setting all computers to disabled..."
# set UAC to disabled for all computers
$output = ""
$userCount = 1
ForEach ($line in (Get-Content $ExportFileTemp)) {
    If ($line -like "userAccountControl:*") {
        $line = "userAccountControl: 4098"
    }

    # write to file after each user is processed to avoid newlines appearing in the middle of computers
        # which generate errors
    If ($line -like "dn:*") {
        Write-Host "Writing computer $userCount to file..."
        $userCount += 1
        $output >> $ExportFile
        $output = ""
    }

    $output += $line + "`r`n"
}
$output >> $ExportFile

Remove-Item $ExportFileTemp
