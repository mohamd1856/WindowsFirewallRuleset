
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020-2023 metablaster zebal@protonmail.ch

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
Unit test for Initialize-Provider

.DESCRIPTION
Test correctness of Initialize-Provider function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Initialize-Provider.ps1

.INPUTS
None. You cannot pipe objects to Initialize-Provider.ps1

.OUTPUTS
None. Initialize-Provider.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Initialize-Provider"

if ($Force -or $PSCmdlet.ShouldContinue("Possible to install package provider", "Accept potentially dangerous unit test"))
{
	if (!($ProjectCheck -and $ModulesCheck))
	{
		Write-Error -Category NotEnabled -TargetObject $ThisScript `
			-Message "This unit test requires ProjectCheck and ModulesCheck variables to be set"
		return
	}

	Start-Test "NuGet"
	$Result = Initialize-Provider -ProviderName "NuGet" -RequiredVersion $RequireNuGetVersion `
		-InfoMessage "Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider"
	$Result

	Start-Test "Chocolatey"
	Initialize-Provider -ProviderName "Chocolatey" -RequiredVersion "0.0.79" -InfoMessage "Test installing Chocolatey"

	$Result
	Test-Output $Result -Command Initialize-Provider
}

Update-Log
Exit-Test
