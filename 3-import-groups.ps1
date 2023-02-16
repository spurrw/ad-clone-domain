<# Import group to target domain. Deletes target groups if they already exist and recreates them.
#>

param(
    [string]$ExportFileGroups="groups-custom.json",

    [string]$SourceDN="DC=ad,DC=contoso,DC=com",
    [string]$TargetDN="DC=tstad,DC=contoso,DC=com"
)

If (-not (Test-Path $ExportFileGroups)) {
    Write-Host "$ExportFileGroups does not exist"
    exit
}

$groups = Get-Content $ExportFileGroups | ConvertFrom-Json
$groupCount = 1
ForEach ($group in $groups) {
    # only care about groups not in default Users OU
    If (-not (($group.DistinguishedName -like "*CN=Users,DC=*") -or ($group.DistinguishedName -like "*CN=Builtin,DC=*"))) {
        Write-Host "Importing group $groupCount of $($groups.Length) - $($group.Name)..."
        $groupCount += 1

        # delete group if it already exists
        If ((@(Get-ADGroup $group.Name -ErrorAction SilentlyContinue)).Length -gt 0) {
            Write-Host "  Deleting group"
            Remove-ADGroup $group.Name -Confirm:$false
        }

        $path = $group.DistinguishedName.Substring($group.Name.Length + 4)
        $path = $path.Substring(0, $path.Length - $SourceDN.Length) + $TargetDN

        # create new group
        Write-Host "  Creating group"
        New-ADGroup -Name $group.Name -GroupScope $group.GroupScope -GroupCategory $group.GroupCategory -Path $path
    }
}

# add group members
$groupCount = 1
ForEach ($group in $groups) {
    # only care about groups not in default Users OU
    If (-not (($group.DistinguishedName -like "*CN=Users,DC=*") -or ($group.DistinguishedName -like "*CN=Builtin,DC=*"))) {
        Write-Host "Adding group members to group $groupCount of $($groups.Length) - $($group.Name)..."
        $groupCount += 1

        If ($group.Members.Length -gt 0) {
            Write-Host "  Adding members"
            Add-ADGroupMember $group.SamAccountName -Members $group.Members
        }
    }
}

Write-Host "Groups have been deleted and recreated. You'll want to re-run the GPO import script because that script grants permissions to GPOs to now-deleted groups."
