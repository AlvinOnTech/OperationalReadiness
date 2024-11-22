<#
.Synopsis
    Windows 11 SOE Testing Script
.DESCRIPTION
    This script uses Pester to test the configuration of a Windows 11 SOE
    Tests are grouped by function
    Describe 'Function' {
        It 'Describe the test' {
            PowerShell for the tes
        }
    }
    Documentation for Pester is available at https://pester.dev/docs/quick-start
.EXAMPLE
   .\TestingScript.ps1
.NOTES
    Author:       Alvin Hall (alvin_hall@data3.com.au)
    Date Created: 2024-10-10
    Version History:
    - 2024-10-10
        Initial script and folder structure creation
#>

If (!(Get-Module -Name Pester | Where-Object { $_.Version -gt 5.6 })) {
    Install-Module -Name Pester -MinimumVersion 5.6 -Force -SkipPublisherCheck
}
Import-Module -Name Pester -MinimumVersion 5.6

#region Load helper functions
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$functionPath = "$scriptPath\Functions"

$helperFunctions = @(Get-ChildItem -Path $functionPath -Filter "*.ps1" -ErrorAction SilentlyContinue)

Foreach($import in $helperFunctions) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}
#endregion

#region Pester Tests
Describe 'Windows Version and Edition' {
    BeforeAll {
        $CIM_OS = Get-CimInstance -Namespace 'Root/CIMv2' -ClassName 'Win32_OperatingSystem'
    }

    It 'OS Version should be Windows 11 23H2' {
        $CIM_OS.Version | Should -Be '10.0.22631'
    }
    It 'OS Caption should be "Microsoft Windows 11 Pro"' {
        $CIM_OS.Caption | Should -Be 'Microsoft Windows 11 Pro'
    }
}

Describe 'Installed Applications' {
    BeforeAll {
        $InstalledPrograms = Get-ARPEntries
    }
    
    It 'Google Chrome should be installed and at least version v129.0.6668.90 ' {
        $Chrome = $InstalledPrograms | Where-Object { $_.DisplayName -eq 'Google Chrome' } -ErrorAction Continue
        { Get-Variable -Name Chrome -ErrorAction Stop } | Should -Not -Throw
        [version]($Chrome.Version) -ge [version]'129.0.6668.90' | Should -Be $true
    }
}

#endregion