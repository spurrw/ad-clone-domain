<# Imports GPO backups in a folder to the domain. Imports GPO settings also. #>

param(
    [parameter(Mandatory=$true)]
    [string]$BackupDIR
)

If (-not (Test-Path $BackupDIR)) {
    Write-Host "Path doesn't exist $BackupDIR"
    exit
}
$BackupDIR = Resolve-Path $BackupDIR

ForEach ($gpo in Get-ChildItem $BackupDIR) {
    $gpreport = Join-Path -Path $gpo.FullName -ChildPath "gpreport.xml"
    $found = $false
    $name = ""

    # getting GPO names
    ForEach ($line in (Get-Content $gpreport)) {
        If ($line -like "*<Name>*") {
            $name = $line.Substring($line.IndexOf("<Name>")+6, $line.IndexOf("</Name")-8)
            $found = $true
        }
        If ($found) {
            break
        }
    }

    Write-Host "Importing GPO $name"

    # delete current GPO if it exists
    If ((@(Get-GPO $name -ErrorAction SilentlyContinue)).Length -gt 0) {
        try {
            Remove-GPO -Name $name
        } catch {
            Write-Host "  Error removing $name"
            Write-Host $_
        }
    }

    # create blank GPO if it doesn't exist
    If ((@(Get-GPO $name -ErrorAction SilentlyContinue)).Length -eq 0) {
        try {
            New-GPO -Name $name | Select-Object DisplayName
        } catch {
            Write-Host "  Error creating $name"
            Write-Host $_
            continue
        }
    }

    # removes Authenticated Users from permissions, which are there by default, but not all GPOs have this
    try {
        Set-GPPermission -Name $name -TargetName "Authenticated Users" -TargetType Group  -PermissionLevel GpoRead -Replace
    } catch {
        Write-Host "  Error removing Authenticated Users from Security Filtering"
        Write-Host $_
    }

    # import GPO settings
    try {
        Import-GPO -BackupGpoName $name -TargetName $name -Path $BackupDIR
    } catch {
        Write-Host "  Error importing $name"
        Write-Host $_
    }

    # import GPO permissions
    $permissions = Get-Content (Join-Path -Path $gpo.FullName -ChildPath "permissions.json") | ConvertFrom-Json
    ForEach ($perm in $permissions) {
        If (-not ($perm.Inherited)) {
            Write-Host "  Setting permission for $name for object $($perm.Trustee.Name) with permission $($perm.Permission)"
            Set-GPPermission -Name $name -TargetName $perm.Trustee.Name -TargetType $perm.TrusteeType -PermissionLevel $perm.Permission
        }
    }

    # import GPO links
    # parse XML from gpreport.xml
    $links = ([xml](Get-Content $gpreport)).GPO.LinksTo
    # read links
    ForEach ($link in $links) {
        # create OU DN from SOMPath string
        $pathParts = $link.SOMPath.Split("/")
        $OU = "DC=tstad,DC=contoso,DC=com"
        For ($x = 1; $x -lt $pathParts.Length; $x += 1) {
            $OU = "OU=" + $pathParts[$x] + "," + $OU
        }
        # link enabled or not?
        $enabled = If ($link.Enabled -eq "true" -or $link.Enabled -eq $true) {"Yes"} Else {"No"}

        # create OU link
        Write-Host "  Linking GPO $name to $OU. Enabled? $enabled"
        try {
            New-GPLink -Name $name -Target $OU -LinkEnabled $enabled
        } catch {
            Write-Host "  Error linking $name to $OU. Enabled? $enabled"
            Write-Host $_
        }
    }
    Write-Host
}

Write-Host
Write-Host "All done importing GPOs. You'll need to import WMI filters next, but WMI filter must be MANUALLY LINKED to GPOs."
