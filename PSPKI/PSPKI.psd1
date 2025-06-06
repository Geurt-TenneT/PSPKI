@{

    # Script module or binary module file associated with this manifest
    RootModule = 'PSPKI.psm1'

    # Version number of this module.
    ModuleVersion = '4.3.0'

    # ID used to uniquely identify this module
    GUID = '08a70230-ae58-48af-ae73-e4276b6ef1eb'

    # Author of this module
    Author = 'Vadims Podans'

    # Company or vendor of this module
    CompanyName = 'PKI Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2011 - 2024 PKI Solutions. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'This module contains public key infrastructure and certificate management functions. Support site: https://www.pkisolutions.com/tools/pspki/'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'

    # Name of the Windows PowerShell host required by this module
    PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    PowerShellHostVersion = '1.0'

    # Minimum version of the .NET Framework required by this module
    DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = ''

    # Processor architecture (None, X86, Amd64, IA64) required by this module
    ProcessorArchitecture = 'Amd64'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @(
        '.\Library\SysadminsLV.Asn1Parser.dll',
        '.\Library\SysadminsLV.PKI.dll',
        '.\Library\SysadminsLV.PKI.OcspClient.dll',
        '.\Library\SysadminsLV.PKI.Win.dll',
        '.\Library\Interop.CERTADMINLib.dll',
        '.\Library\Interop.CERTCLILib.dll',
        '.\Library\Interop.CERTENROLLLib.dll',
        '.\Library\System.Security.Cryptography.Pkcs.dll'
    )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @('.\Types\PSPKI.Types.ps1xml')

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @('.\Types\PSPKI.Format.ps1xml')

    # Modules to import as nested modules of the module specified in ModuleToProcess
    NestedModules = @()

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport = '*'

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport = '*'

    # List of all modules packaged with this module
    ModuleList = @()

    # List of all files packaged with this module
    FileList = @('PSPKI.psd1','PSPKI.psm1','.\Types\PSPKI.Types.ps1xml','.\Types\PSPKI.Format.ps1xml','about_PSPKI_Module.help.txt','.\Library\SysadminsLV.PKI.dll')

    # Private data to pass to the module specified in ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @("PKI","Certificate","CertificateAuthority","ADCS","X509","X.509")
            ProjectUri = 'https://www.pkisolutions.com/tools/pspki/'
            LicenseUri = 'https://github.com/PKISolutions/PSPKI/blob/master/License.md'
            ReleaseNotes = 'Release notes are available at: https://www.pkisolutions.com/tools/pspki/release-notes-for-pspki-v400'
        }
    }
}