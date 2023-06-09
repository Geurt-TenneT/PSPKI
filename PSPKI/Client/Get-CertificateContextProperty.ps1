function Get-CertificateContextProperty {
<#
.ExternalHelp PSPKI.Help.xml
#>
[OutputType('SysadminsLV.PKI.Cryptography.X509Certificates.X509CertificateContextProperty')]
[OutputType('SysadminsLV.PKI.Cryptography.X509Certificates.X509CertificateContextPropertyCollection')]
[OutputType('SysadminsLV.PKI.Cryptography.X509Certificates.X509CertificatePropertyType[]')]
[CmdletBinding(DefaultParameterSetName = '__name')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [Parameter(ParameterSetName = '__name')]
        [SysadminsLV.PKI.Cryptography.X509Certificates.X509CertificatePropertyType]$PropertyName = "None",
        [Parameter(ParameterSetName = '__list')]
        [switch]$NameList
    )
    process {
        foreach ($cert in $Certificate) {
            switch ($PSCmdlet.ParameterSetName) {
                "__name" {
                    if ($PropertyName -eq "None") {
                        [SysadminsLV.PKI.Utils.CLRExtensions.X509Certificate2Extensions]::GetCertificateContextProperties($cert)
                    } else {
                        [SysadminsLV.PKI.Utils.CLRExtensions.X509Certificate2Extensions]::GetCertificateContextProperty($cert, $PropertyName)
                    }
                }
                "__list" {
                    [SysadminsLV.PKI.Utils.CLRExtensions.X509Certificate2Extensions]::GetCertificateContextPropertyList($cert)
                }
            }
        }
    }
}