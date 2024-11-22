<#
.Synopsis
   Get the Add/Remote Program entries from the local Registry
.DESCRIPTION
   Interrogate both x86 and x64 Uninstall registry keys for a list of installed applications.
.EXAMPLE
   Get-ARPEntries
#>
function Get-ARPEntries
{
    [CmdletBinding()]
    Param  ()

    Begin {
      #region Initialise Variables
      $ARPPath = @{
         'x86' = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
         'x64' = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
      }

      $ARPProps = [ordered]@{
         'DisplayName'  = ''
         'Version'      = ''
         'Publisher'    = ''
         'InstallDate'  = ''
         'Architecture' = ''
         'Key'          = ''
      }

      $OSArch = Get-CimInstance -Namespace 'Root/cimv2' -Class 'Win32_OperatingSystem' | Select-Object -ExpandProperty 'OSArchitecture'
      If ($OSArch -eq '64-bit') { $SysNativeArch = 'x64' }
      Else { $SysNativeArch = 'x86' }
      
      $Return = New-Object -TypeName System.Collections.ArrayList

      #endregion
    }

    Process {
      If ($OSArch -eq '64-bit') {
         #Get the x86 entries
         $InstalledSoftware = Get-ChildItem -Path $ARPPath['x86']
         ForEach ($obj in $InstalledSoftware) {
            $Result = New-Object -TypeName psobject -Property $ARPProps
            $Result.Displayname  = $obj.GetValue('Displayname')
            $Result.Version      = $obj.GetValue('DisplayVersion')
            $Result.Publisher    = $obj.GetValue('Publisher')
            $Result.InstallDate  = $obj.GetValue('InstallDate')
            $Result.Architecture = 'x86'
            $Result.Key          = Split-Path -Path ($obj.Name) -Leaf
            $Return.Add($Result) | Out-Null

            Remove-Variable -Name 'Result'
        }
      }

      #Get the SysNative entries
      $InstalledSoftware = Get-ChildItem -Path $ARPPath['x64']
      ForEach ($obj in $InstalledSoftware) {
         $Result = New-Object -TypeName psobject -Property $ARPProps
         $Result.Displayname  = $obj.GetValue('Displayname')
         $Result.Version      = $obj.GetValue('DisplayVersion')
         $Result.Publisher    = $obj.GetValue('Publisher')
         $Result.InstallDate  = $obj.GetValue('InstallDate')
         $Result.Architecture = $SysNativeArch
         $Result.Key          = Split-Path -Path ($obj.Name) -Leaf
         $Return.Add($Result) | Out-Null

         Remove-Variable -Name 'Result'
      }
      $Return
    }

    End {
      #region Script clean up

      #endregion
    }
}
