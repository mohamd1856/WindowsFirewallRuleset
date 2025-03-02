
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2023 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
Unit test for Search-Installation

.DESCRIPTION
Test correctness of Search-Installation function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Search-Installation.ps1

.INPUTS
None. You cannot pipe objects to Search-Installation.ps1

.OUTPUTS
None. Search-Installation.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
# NOTE: As Administrator because of a test with OneDrive which loads reg hive of other users
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
. $PSScriptRoot\..\ContextSetup.ps1

if ((Get-Variable -Name Develop -Scope Global).Value -eq $false)
{
	Write-Error -Category NotEnabled -TargetObject "Variable 'Develop'" `
		-Message "Unit test $ThisScript is enabled only when 'Develop' variable is set to `$true"
	return
}


Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test

if ($Domain -ne [System.Environment]::MachineName)
{
	# Uses Update-Table
	# Start-Test "Remote 'EdgeChromium' -Domain"
	# Search-Installation "EdgeChromium" -Domain $Domain -Credential $RemotingCredential
	# Get-Variable -Name InstallTable -ErrorAction Ignore |
	# Select-Object -ExpandProperty Value | Format-Table -AutoSize

	Start-Test "Remote 'EdgeChromium' -Session"
	Search-Installation "EdgeChromium" -Session $SessionInstance -CimSession $CimServer
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Format-Table -AutoSize

	# Uses Edit-Table
	Start-Test "Remote 'PowerShell86' -Session"
	Search-Installation "PowerShell86" -Session $SessionInstance -CimSession $CimServer
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Format-Table -AutoSize

	# Uses custom case
	Start-Test "Remote 'NETFramework' -Session"
	Search-Installation "NETFramework" -Session $SessionInstance -CimSession $CimServer
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Format-Table -AutoSize
}
else
{
	$PSDefaultParameterValues["Search-Installation:Session"] = $SessionInstance
	$PSDefaultParameterValues["Search-Installation:CimSession"] = $CimServer

	Start-Test "Search-Installation 'EdgeChromium'"
	Search-Installation "EdgeChromium"
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Format-Table -AutoSize

	Start-Test "Install Root EdgeChromium"
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Select-Object -ExpandProperty InstallLocation

	Start-Test "Search-Installation 'FailureTest'" -Force
	Search-Installation "FailureTest" -EV +TestEV -EA SilentlyContinue
	Restore-Test
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Format-Table -AutoSize

	Start-Test "Search-Installation 'VisualStudio'"
	Search-Installation "VisualStudio"
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Format-Table -AutoSize

	Start-Test "Search-Installation 'Greenshot'"
	Search-Installation "Greenshot"
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Select-Object -ExpandProperty InstallLocation

	Start-Test "Install Root Greenshot"
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Select-Object -ExpandProperty InstallLocation

	Start-Test "Search-Installation 'OneDrive'"
	$Result = Search-Installation "OneDrive"
	$Result
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Format-Table -AutoSize

	Start-Test "Install Root OneDrive"
	Get-Variable -Name InstallTable -ErrorAction Ignore |
	Select-Object -ExpandProperty Value | Select-Object -ExpandProperty InstallLocation

	Test-Output $Result -Command Search-Installation
}

Update-Log
Exit-Test
