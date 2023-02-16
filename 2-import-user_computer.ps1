<# Import users and computers to target domain.
    Could maybe import user passwords, but cannot without LDAPS being used with '-t 636'. Needs a CA to do this.
#>

param(
    [switch]$IgnoreErrors=$false,
    
    [string]$ExportFileUsers="users.txt",
    [string]$ExportFileComputers="computers.txt",
    [string]$ExportFileServiceAccounts="serviceaccounts.txt",

    [string]$DC="tst-dc1.tstad.contoso.com"
)

If ($IgnoreErrors) {
    ldifde -i -f $ExportFileUsers -s $DC -z
    ldifde -i -f $ExportFileComputers -s $DC -z
    #ldifde -i -f $ExportFileServiceAccounts -s $DC -z
}
Else {
    Write-Host "Running ldifde with '-k' option that ONLY ignores Constraint Violation and Object Already Exists errors."
    Write-Host "If there are errors execution will stop."
    Read-Host "Press Enter to continue"
    ldifde -i -f $ExportFileUsers -s $DC -k
    ldifde -i -f $ExportFileComputers -s $DC -k
    #ldifde -i -f $ExportFileServiceAccounts -s $DC -k
}
