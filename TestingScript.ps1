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

If (!(Get-Module -Name Pester | Where-Object { $_.Version -gt [version]5.6 })) {
    Install-Module -Name Pester -MinimumVersion 5.6 -Force -SkipPublisherCheck
}
Import-Module -Name Pester -MinimumVersion 5.6

#region Scriptwide Variables
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#endregion

#region Load helper functions
$functionPath = "$scriptPath\Functions"
$helperFunctions = @(Get-ChildItem -Path $functionPath -Filter "*.ps1" -ErrorAction SilentlyContinue)
Foreach($import in $helperFunctions) {
    Try {
        . $($import.fullname)
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}
#endregion

#region Load tests
$TestsPath = "$scriptPath\Tests"
$TestFiles = Get-ChildItem -Path $TestsPath -Filter "*.json"
#endregion

#region Pester Tests
$testCounter = 0
$testCount = $TestFiles.count
ForEach ($TestFile in $TestFiles) {
    $testCounter++
    $testJson = Get-Content -Path $TestFile.fullname |  Out-String | ConvertFrom-Json
    Write-Progress -id 1 -Activity "Running tests" -Status "Running test cases for $($testJson.TestName)" -PercentComplete (($testCounter/$testCount)*100)
    ForEach ($category in $($testJson.Categories)) {
        ForEach ($Test in $($category.Tests)) {
            Write-Progress -id 2 -Activity "Running $($TestFile.TestName) tests" -Status "Running test: $($Test.TestName)" -PercentComplete (($testCounter/$testCount)*100)
            #Start-Sleep -milliseconds 10
            Describe "$($Test.TestName)" {
                Switch ($Test.TestType) {
                    'AddRemove' {
                        BeforeAll {
                            $InstalledPrograms = Get-ARPEntries
                        }
                        It " Program $($Test.DisplayName) is installed and at least version $($Test.MinimumVersion)" {
                            $Application = $InstalledPrograms | Where-Object { $_.DisplayName -eq $($Test.DisplayName) } -ErrorAction Continue
                            { Get-Variable -Name Application -ErrorAction Stop } | Should -Not -Throw
                            {[version]$($Application.Version) -ge [version]$($Test.MinimumVersion)} | Should -Be $true
                        }
                    }
                    'RegistryValue' {
                        It "$($Test.TestName) is set to $($Test.Setting)" {
                            (Get-ItemProperty -Path $Test.RegistryPath).$($Test.Value) -eq $($Test.Data) | Should -be $true
                        }
                    }
                    default {
                        # Write-Host "Unknown Test Type" -ForegroundColor Red -BackgroundColor Yellow
                    }
                }
            }
        }
    }
}
#endregion