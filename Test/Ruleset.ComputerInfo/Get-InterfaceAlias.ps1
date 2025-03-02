
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
Unit test for Get-InterfaceAlias

.DESCRIPTION
Test correctness of Get-InterfaceAlias function

.PARAMETER Domain
If specified, only remoting tests against specified computer name are performed

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-InterfaceAlias.ps1

.INPUTS
None. You cannot pipe objects to Get-InterfaceAlias.ps1

.OUTPUTS
None. Get-InterfaceAlias.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

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
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Get-InterfaceAlias"
$SessionParams = @{
	Verbose = $true
}

if ($Domain -ne [System.Environment]::MachineName)
{
	$SessionParams.Session = $SessionInstance
}

Start-Test "default"
$Result = Get-InterfaceAlias @SessionParams
if ($Result) { $Result.ToWql() }

Start-Test "-AddressFamily IPv4"
$Aliases = Get-InterfaceAlias -AddressFamily IPv4 @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Start-Test "-AddressFamily IPv6"
$Aliases = Get-InterfaceAlias -AddressFamily IPv6 @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Start-Test "-WildCardOption"
$Aliases = Get-InterfaceAlias -WildCardOption IgnoreCase @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Start-Test "-Virtual"
$Aliases = Get-InterfaceAlias -Virtual @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Start-Test "-AddressFamily IPv4 -Physical"
$Aliases = Get-InterfaceAlias -AddressFamily IPv4 -Physical @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Start-Test "-AddressFamily IPv4 -Virtual"
$Aliases = Get-InterfaceAlias -AddressFamily IPv4 -Virtual @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Start-Test "-Hidden"
$Aliases = Get-InterfaceAlias -Hidden @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Start-Test "-Virtual  -Hidden"
$Aliases = Get-InterfaceAlias -Virtual -Hidden @SessionParams
if ($Aliases) {	$Aliases.ToWql() }

Test-Output $Result -Command Get-InterfaceAlias

Update-Log
Exit-Test
