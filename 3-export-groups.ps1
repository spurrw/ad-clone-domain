<# Export group from source domain. 
    Cannot export and import memberOf attribute if all the memberOf's don't exist. 
    Run this as Domain Admin if you have groups that can't be read by normal users. #>


param(
    [string]$ExportFileGroups="groups.json"
)

# export groups without members
try {
    $groupsExport = Get-ADGroup -Filter * | Select-Object Name,SamAccountName,DistinguishedName,GroupCategory,GroupScope
} catch {
    Write-Host "Error looking up groups from AD"
    Write-Host $_
    exit
}

# custom objects to save strings that get turned into ints
$groups = @()
$groupCount = 1
ForEach ($group in $groupsExport) {
    Write-Host "Looking up group $groupCount of $($groupsExport.Length) - $($group.Name)..."
    $groupCount += 1

    # lookup group members
    try {
        $membersExport = Get-ADGroupMember $group.SamAccountName | Select-Object SamAccountName
    } catch {
        $membersExport = @()
    }
    # make a flat list, otherwise you get inconsistent exports of object info into json
    $members = @()
    ForEach ($member in $membersExport) {
        $members += $member.SamAccountName
    }
    
    $groups += [PSCustomObject]@{
        Name = $group.Name
        SamAccountName = $group.SamAccountName
        DistinguishedName = $group.DistinguishedName
        GroupCategory = $group.GroupCategory.ToString()
        GroupScope = $group.GroupScope.ToString()
        Members = $members
    }
}

# write group info to json file
$groups | ConvertTo-Json > $ExportFileGroups


