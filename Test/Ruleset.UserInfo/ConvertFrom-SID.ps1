
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
Unit test for ConvertFrom-SID

.DESCRIPTION
Test correctness of ConvertFrom-SID function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\ConvertFrom-SID.ps1

.INPUTS
None. You cannot pipe objects to ConvertFrom-SID.ps1

.OUTPUTS
None. ConvertFrom-SID.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1
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

Initialize-Project
Import-Module -Name Ruleset.UserInfo
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "ConvertFrom-SID"

$SessionParams = @{}

if ($Domain -ne [System.Environment]::MachineName)
{
	Start-Test "'Users', 'Administrators'" -Command "Get-GroupPrincipal"
	$UserAccounts = Get-GroupPrincipal "Users", "Administrators" -CimSession $CimServer
	$UserAccounts | Select-Object *

	$SessionParams["Session"] = $SessionInstance
	$SessionParams["CimSession"] = $CimServer
}
else
{
	Start-Test "'Users', 'Administrators'" -Command "Get-GroupPrincipal"
	$UserAccounts = Get-GroupPrincipal "Users", "Administrators"
	$UserAccounts
}

Start-Test "NT SYSTEM, NT LOCAL SERVICE" -Command "Get-PrincipalSID"
$NTAccounts = Get-PrincipalSID -Domain "NT AUTHORITY" -User "SYSTEM", "LOCAL SERVICE"
$NTAccounts

Start-Test "users and admins"
$AccountSIDs = @()
foreach ($Account in $UserAccounts)
{
	$AccountSIDs += $Account.SID
}
$AccountSIDs | ConvertFrom-SID @SessionParams | Format-Table

Start-Test "NT AUTHORITY users"
foreach ($Account in $NTAccounts)
{
	ConvertFrom-SID $Account.SID @SessionParams | Format-Table
}

Start-Test "Unknown domain" -Force
ConvertFrom-SID "S-1-5-21-0000-0000-1111-1111" @SessionParams -EV +TestEV -EA SilentlyContinue | Format-Table
Restore-Test

Start-Test "unknown SID" -Force
ConvertFrom-SID "S-1-5-9999" @SessionParams -EV +TestEV -EA SilentlyContinue | Format-Table
Restore-Test

Start-Test "App SID for Microsoft.AccountsControl"
$AppSID = "S-1-15-2-969871995-3242822759-583047763-1618006129-3578262429-3647035748-2471858633"
$AppResult = ConvertFrom-SID $AppSID @SessionParams
$AppResult | Format-Table

Start-Test "nonexistent App SID" -Force
$AppSID = "S-1-15-2-2967553933-3217682302-0000000000000000000-2077017737-3805576244-585965800-1797614741"
$AppResult2 = ConvertFrom-SID $AppSID @SessionParams -EV +TestEV -EA SilentlyContinue
$AppResult2 | Format-Table
Restore-Test

Start-Test "APPLICATION PACKAGE AUTHORITY"
$AppSID = "S-1-15-2-2"
$PackageResult = ConvertFrom-SID @SessionParams $AppSID
$PackageResult | Format-Table

Start-Test "Capability"
$AppSID = "S-1-15-3-12345"
$PackageResult = ConvertFrom-SID @SessionParams $AppSID
$PackageResult | Format-Table

Test-Output $AppResult -Command ConvertFrom-SID -Force

Update-Log
Exit-Test
