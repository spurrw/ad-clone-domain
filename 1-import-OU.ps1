<# Import OUs to target domain.
#>

param(
    [switch]$IgnoreErrors=$false,

    [string]$ExportFile="OUs.txt",

    [string]$DC="tst-dc1.tstad.contoso.com"
)

If (-not (Test-Path $ExportFile)) {
    Write-Host "$ExportFile does not exist"
    exit
}

If ($IgnoreErrors) {
    ldifde -i -f $ExportFile -s $DC -z
}
Else {
    Write-Host "Running ldifde with '-k' option that ONLY ignores Constraint Violation and Object Already Exists errors."
    Write-Host "If there are errors execution will stop."
    Read-Host "Press Enter to continue"
    ldifde -i -f $ExportFile -s $DC -k
}
