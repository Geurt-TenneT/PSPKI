#region assembly import
Add-Type -Path $PSScriptRoot\Library\SysadminsLV.Asn1Parser.dll -ErrorAction Stop
Add-Type -Path $PSScriptRoot\Library\SysadminsLV.PKI.dll -ErrorAction Stop
Add-Type -AssemblyName System.Security -ErrorAction Stop
#endregion

#region global variable section
[Version]$OSVersion = [Environment]::OSVersion.Version
[bool]$PsIsCore = if ($PSVersionTable.PSEdition -like "*core*") {$true} else {$false}
# compatibility
[bool]$NoDomain = $true # computer is a member of workgroup
try {
    $Domain = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
    $PkiConfigContext = "CN=Public Key Services,CN=Services,$Domain"
    $NoDomain = $false
} catch {$NoDomain = $true}

[bool]$NoCAPI = $true   # CertAdm.dll server managemend library is missing
if (Test-Path $PSScriptRoot\Server) {
    try {
        $CertAdmin = New-Object -ComObject CertificateAuthority.Admin
        $NoCAPI = $false
    } catch {$NoCAPI = $true}
}
[bool]$NoCAPIv2 = $true # referring to enrollment web services support
$NoCAPIv2 = if (
        $OSVersion.Major -lt 6 -or
        ($OSVersion.Major -eq 6 -and
        $OSVersion.Minor -lt 1)
    ) {$true} else {$false}


$RegPath = "System\CurrentControlSet\Services\CertSvc\Configuration"
# os version map
$Win2003    = if ($OSVersion.Major -lt 6) {$true} else {$false}
$Win2008    = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 0) {$true} else {$false}
$Win2008R2  = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 1) {$true} else {$false}
$Win2012    = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 2) {$true} else {$false}
$Win2012R2  = if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 3) {$true} else {$false}
$Win2016    = if ($OSVersion.Major -eq 10 -and $OSVersion.Minor -eq 0) {$true} else {$false}
# warning messages
$RestartRequired = @"
New {0} are set, but will not be applied until Certification Authority service is restarted.
In future consider to use '-RestartCA' switch for this cmdlet to restart Certification Authority service immediatelly when new settings are set.

See more: Start-CertificationAuthority, Stop-CertificationAuthority and Restart-CertificationAuthority cmdlets.
"@
$NothingIsSet = @"
Input object was not modified since it was created. Nothing is written to the CA configuration.
"@
#endregion

#region helper functions
function Ping-ICertAdmin ($ConfigString) {
    $success = $true
    try {
        $CertAdmin = New-Object -ComObject CertificateAuthority.Admin
        $var = $CertAdmin.GetCAProperty($ConfigString,0x6,0,4,0)
    } catch {$success = $false}
    $success
}

function Write-ErrorMessage {
    param (
        [PKI.Utils.PSErrorSourceEnum]$Source,
        $ComputerName,
        $ExtendedInformation
    )
$DCUnavailable = @"
"Active Directory domain could not be contacted.
"@
$CAPIUnavailable = @"
Unable to locate required assemblies. This can be caused if attempted to run this module on a client machine where AdminPack/RSAT (Remote Server Administration Tools) are not installed.
"@
$WmiUnavailable = @"
Unable to connect to CA server '$ComputerName'. Make sure if Remote Registry service is running and you have appropriate permissions to access it.
Also this error may indicate that Windows Remote Management protocol exception is not enabled in firewall.
"@
$XchgUnavailable = @"
Unable to retrieve any 'CA Exchange' certificates from '$ComputerName'. This error may indicate that target CA server do not support key archival. All requests which require key archival will immediately fail.
"@
    switch ($source) {
        DCUnavailable {
            Write-Error -Category ObjectNotFound -ErrorId "ObjectNotFoundException" `
            -Message $DCUnavailable
        }
        CAPIUnavailable {
            Write-Error -Category NotImplemented -ErrorId "NotImplementedException" `
            -Message $NoCAPI; exit
        }
        CAUnavailable {
            Write-Error -Category ResourceUnavailable -ErrorId ResourceUnavailableException `
            -Message "Certificate Services are either stopped or unavailable on '$ComputerName'."
        }
        WmiUnavailable {
            Write-Error -Category ResourceUnavailable -ErrorId ResourceUnavailableException `
            -Message $WmiUnavailable
        }
        WmiWriteError {
            try {$text = Get-ErrorMessage $ExtendedInformation}
            catch {$text = "Unknown error '$code'"}
            Write-Error -Category NotSpecified -ErrorId NotSpecifiedException `
            -Message "An error occured during CA configuration update: $text"
        }
        ADKRAUnavailable {
            Write-Error -Category ObjectNotFound -ErrorId "ObjectNotFoundException" `
            -Message "No KRA certificates found in Active Directory."
        }
        ICertAdminUnavailable {
            Write-Error -Category ResourceUnavailable -ErrorId ResourceUnavailableException `
            -Message "Unable to connect to management interfaces on '$ComputerName'"
        }
        NoXchg {
            Write-Error -Category ObjectNotFound -ErrorId ObjectNotFoundException `
            -Message $XchgUnavailable
        }
        NonEnterprise {
            Write-Error -Category NotImplemented -ErrorAction NotImplementedException `
            -Message "Specified Certification Authority type is not supported. The CA type must be either 'Enterprise Root CA' or 'Enterprise Standalone CA'."
        }
    }
}
#endregion

#region module installation stuff
# dot-source all function files
Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Foreach-Object { . $_.FullName }
$aliases = @()
if ($Win2008R2 -and (Test-Path $PSScriptRoot\Server)) {
    New-Alias -Name Add-CEP                 -Value Add-CertificateEnrollmentPolicyService -Force
    New-Alias -Name Add-CES                 -Value Add-CertificateEnrollmentService -Force
    New-Alias -Name Remove-CEP              -Value Remove-CertificateEnrollmentPolicyService -Force
    New-Alias -Name Remove-CES              -Value Remove-CertificateEnrollmentService -Force
    New-Alias -Name Get-DatabaseRow         -Value Get-AdcsDatabaseRow -Force
    $aliases += "Add-CEP", "Add-CES", "Remove-CEP", "Remove-CES", "Get-DatabaseRow"
}
if (($Win2008 -or $Win2008R2) -and (Test-Path $PSScriptRoot\Server)) {
    New-Alias -Name Install-CA                  -Value Install-CertificationAuthority -Force
    New-Alias -Name Uninstall-CA                -Value Uninstall-CertificationAuthority -Force
    $aliases += "Install-CA", "Uninstall-CA"
}
if (!$NoDomain) {
    New-Alias -Name Add-AdCrl                   -Value Add-AdCertificateRevocationList -Force
    New-Alias -Name Remove-AdCrl                -Value Add-AdCertificateRevocationList -Force
    $aliases += "Add-AdCrl ", "Remove-AdCrl"
}
if (!$NoDomain -and (Test-Path $PSScriptRoot\Server)) {
    New-Alias -Name Get-CA                      -Value Get-CertificationAuthority -Force
    New-Alias -Name Get-KRAFlag                 -Value Get-KeyRecoveryAgentFlag -Force
    New-Alias -Name Enable-KRAFlag              -Value Enable-KeyRecoveryAgentFlag -Force
    New-Alias -Name Disable-KRAFlag             -Value Disable-KeyRecoveryAgentFlag -Force
    New-Alias -Name Restore-KRAFlagDefault      -Value Restore-KeyRecoveryAgentFlagDefault -Force
    $aliases += "Get-CA", "Get-KRAFlag", "Enable-KRAFlag", "Disable-KRAFlag", "Restore-KRAFlagDefault"
}
if (Test-Path $PSScriptRoot\Server) {
    New-Alias -Name Connect-CA                  -Value Connect-CertificationAuthority -Force
    
    New-Alias -Name Add-AIA                     -Value Add-AuthorityInformationAccess -Force
    New-Alias -Name Get-AIA                     -Value Get-AuthorityInformationAccess -Force
    New-Alias -Name Remove-AIA                  -Value Remove-AuthorityInformationAccess -Force
    New-Alias -Name Set-AIA                     -Value Set-AuthorityInformationAccess -Force

    New-Alias -Name Add-CDP                     -Value Add-CRLDistributionPoint -Force
    New-Alias -Name Get-CDP                     -Value Get-CRLDistributionPoint -Force
    New-Alias -Name Remove-CDP                  -Value Remove-CRLDistributionPoint -Force
    New-Alias -Name Set-CDP                     -Value Set-CRLDistributionPoint -Force
    
    New-Alias -Name Get-CRLFlag                 -Value Get-CertificateRevocationListFlag -Force
    New-Alias -Name Enable-CRLFlag              -Value Enable-CertificateRevocationListFlag -Force
    New-Alias -Name Disable-CRLFlag             -Value Disable-CertificateRevocationListFlag -Force
    New-Alias -Name Restore-CRLFlagDefault      -Value Restore-CertificateRevocationListFlagDefault -Force
    
    New-Alias -Name Remove-Request              -Value Remove-DatabaseRow -Force
    
    New-Alias -Name Get-CAACL                   -Value Get-CASecurityDescriptor -Force
    New-Alias -Name Add-CAACL                   -Value Add-CAAccessControlEntry -Force
    New-Alias -Name Remove-CAACL                -Value Remove-CAAccessControlEntry -Force
    New-Alias -Name Set-CAACL                   -Value Set-CASecurityDescriptor -Force
    $aliases += "Connect-CA", "Add-AIA", "Get-AIA", "Remove-AIA", "Add-CDP", "Get-CDP", "Remove-CDP",
        "Set-CDP", "Get-CRLFlag", "Enable-CRLFlag", "Disable-CRLFlag", "Restore-CRLFlagDefault",
        "Remove-Request", "Get-CAACL", "Add-CAACL", "Remove-CAACL", "Set-CAACL"
}

if (Test-Path $PSScriptRoot\Client) {
    New-Alias -Name "oid"                       -Value Get-ObjectIdentifier -Force
    New-Alias -Name oid2                        -Value Get-ObjectIdentifierEx -Force

    New-Alias -Name Get-Csp                     -Value Get-CryptographicServiceProvider -Force

    New-Alias -Name Get-CRL                     -Value Get-CertificateRevocationList -Force
    New-Alias -Name Show-CRL                    -Value Show-CertificateRevocationList -Force
    New-Alias -Name Get-CTL                     -Value Get-CertificateTrustList -Force
    New-Alias -Name Show-CTL                    -Value Show-CertificateTrustList -Force
    $aliases += "oid", "oid2", "Get-CRL", "Show-CRL", "Get-CTL", "Show-CTL"
}

# define restricted functions
$RestrictedFunctions =      "Get-RequestRow",
                            "Ping-ICertAdmin",
                            "Write-ErrorMessage"
$NoDomainExcludeFunctions = "Get-AdPkicontainer",
                            "Add-AdCertificate",
                            "Remove-AdCertificate",
                            "Add-AdCertificateRevocationList",
                            "Remove-AdCertificateRevocationList",
                            "Add-CAKRACertificate",
                            "Add-CATemplate",
                            "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Add-CertificateTemplateAcl",
                            "Disable-KeyRecoveryAgentFlag",
                            "Enable-KeyRecoveryAgentFlag",
                            "Get-ADKRACertificate",
                            "Get-CAExchangeCertificate",
                            "Get-CAKRACertificate",
                            "Get-CATemplate",
                            "Get-CertificateTemplate",
                            "Get-CertificateTemplateAcl",
                            "Get-EnrollmentServiceUri",
                            "Get-KeyRecoveryAgentFlag",
                            "Remove-CAKRACertificate",
                            "Remove-CATemplate",
                            "Remove-CertificateTemplate",
                            "Remove-CertificateTemplateAcl",
                            "Restore-KeyRecoveryAgentFlagDefault",
                            "Set-CAKRACertificate",
                            "Set-CATemplate",
                            "Set-CertificateTemplateAcl",
                            "Get-CertificationAuthority"
$Win2003ExcludeFunctions =  "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Install-CertificationAuthority",
                            "Remove-CertificateEnrollmentPolicyService",
                            "Remove-CertificateEnrollmentService",
                            "Uninstall-CertificationAuthority"  
$Win2008ExcludeFunctions =  "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Remove-CertificateEnrollmentPolicyService",
                            "Remove-CertificateEnrollmentService"
$Win2012ExcludeFunctions =  "Install-CertificationAuthority",
                            "Uninstall-CertificationAuthority",
                            "Add-CertificateEnrollmentPolicyService",
                            "Add-CertificateEnrollmentService",
                            "Remove-CertificateEnrollmentPolicyService",
                            "Remove-CertificateEnrollmentService"

if ($Win2003) {$RestrictedFunctions += $Win2003ExcludeFunctions}
if ($Win2008) {$RestrictedFunctions += $Win2008ExcludeFunctions}
if ($Win2012) {$RestrictedFunctions += $Win2012ExcludeFunctions}
if ($Win2012R2) {$RestrictedFunctions += $Win2012ExcludeFunctions}
if ($Win2016) {$RestrictedFunctions += $Win2012ExcludeFunctions}
if ($NoDomain) {$RestrictedFunctions += $NoDomainExcludeFunctions}
# do not export any function from Server folder when RSAT is not installed.
# only client components are exported
if ($NoCAPI) {
    $RestrictedFunctions += Get-ChildItem $PSScriptRoot\Server -Filter "*.ps1" | ForEach-Object {$_.BaseName}
    Write-Warning @"
Active Directory Certificate Services remote administration tools (RSAT) are not installed and only
client-side functionality will be available.
"@
}
# export module members
Export-ModuleMember –Function @(
    Get-ChildItem $PSScriptRoot -Include *.ps1 -Recurse | `
        ForEach-Object {$_.Name -replace ".ps1"} | `
        Where-Object {$RestrictedFunctions -notcontains $_}
)
Export-ModuleMember -Alias $aliases
#endregion
# conditional type data
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Update-TypeData -AppendPath $PSScriptRoot\Types\PSPKI.PS5Types.ps1xml
}