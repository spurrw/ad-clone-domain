<# Clone GPOs from one domain to another. #>

param(
    [string]$ExportDir="gpo"
)

If (-not (Test-Path $ExportDir)) {
    mkdir $ExportDir
}
Else {
    Remove-Item -Recurse "$ExportDir/*" -Force
}

$ExportDir = Resolve-Path $ExportDir

# Export GPOs from source domain. Full filepath must be specified to -Path
Backup-GPO -All -Path $ExportDir
#Backup-GPO -Guid "{AEE3D266-81A0-4DEC-AB65-19E361E728C3}" -Path $ExportDir

# Export GPO permissions as JSON
ForEach ($gpo in Get-ChildItem $ExportDir) {
    $guid = ([xml](Get-Content (Join-Path -Path $gpo.FullName -ChildPath "gpreport.xml"))).GPO.Identifier.Identifier."#text"
    $permissionsExport = Get-GPPermission -All -Guid $guid

    # export permissions a custom object where we can prevent the .Permission and .TrusteeType attribute getting
        # turned into a number
    $permissions = @()
    ForEach ($perm in $permissionsExport) {
        # if type == WellKnownGroup, target domain doesn't know what WellKnownGroup is
        If ($perm.Trustee.SidType.ToString() -eq "WellKnownGroup") {
            $TrusteeType = "Group"
        }
        Else {
            $TrusteeType = $perm.Trustee.SidType.ToString()
        }

        $permissions += [PSCustomObject]@{
            Denied = $perm.Denied
            Inheritable = $perm.Inheritable
            Inherited = $perm.Inherited
            Trustee = $perm.Trustee
            Permission = $perm.Permission.ToString()
            TrusteeType = $TrusteeType
        }
    }
    $permissions | ConvertTo-Json > (Join-Path -Path $gpo.FullName -ChildPath "permissions.json")

}
