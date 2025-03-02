
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2023 metablaster zebal@protonmail.ch

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
Outbound firewall rules for nmap

.DESCRIPTION
Outbound firewall rules for nmap,
Nmap ("Network Mapper") is a free and open source utility for network discovery and security auditing.

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Trusted
If specified, rules will be loaded for executables with missing or invalid digital signature.
By default an error is generated and rule isn't loaded.

.PARAMETER Interactive
If program installation directory is not found, script will ask user to
specify program installation location.

.PARAMETER Quiet
If specified, it suppresses warning, error or informationall messages if user specified or default
program path does not exist or if it's of an invalid syntax needed for firewall.

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> OutboundRule

.INPUTS
None. You cannot pipe objects to OutboundRule.ps1

.OUTPUTS
None. OutboundRule.ps1 does not generate any output

.NOTES
TODO: Testing needed, also unsure if zenmap needs internet access

.LINK
https://nmap.org
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Trusted,

	[Parameter()]
	[switch] $Interactive,

	[Parameter()]
	[switch] $Quiet,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\..\DirectionSetup.ps1

# Setup local variables
$Group = "Software - nmap"
$Accept = "Outbound rules for nmap network scanner"
$Deny = "Skip operation, no rules will be loaded for nmap"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }

$PSDefaultParameterValues["Confirm-Installation:Quiet"] = $Quiet
$PSDefaultParameterValues["Confirm-Installation:Interactive"] = $Interactive
$PSDefaultParameterValues["Test-ExecutableFile:Quiet"] = $Quiet
$PSDefaultParameterValues["Test-ExecutableFile:Force"] = $Trusted -or $SkipSignatureCheck
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

# nmap installation directories
$NmapProgramRoot = "%ProgramFiles(x86)%\Nmap444"

#
# Rules for nmap
#

# Test if installation exists on system
if ((Confirm-Installation "nmap" ([ref] $NmapProgramRoot)) -or $ForceLoad)
{
	$Program = "$NmapProgramRoot\nmap.exe"
	if ((Test-ExecutableFile $Program) -or $ForceLoad)
	{
		New-NetFirewallRule -DisplayName "nmap TCP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "nmap UDP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-LocalOnlyMapping $false -LooseSourceMapping $false `
			-Description "" |
		Format-RuleOutput

		New-NetFirewallRule -DisplayName "nmap ICMP" `
			-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
			-Service Any -Program $Program -Group $Group `
			-Enabled False -Action Allow -Direction $Direction -Protocol ICMPv4 `
			-LocalAddress Any -RemoteAddress Any `
			-LocalPort Any -RemotePort Any `
			-LocalUser $UsersGroupSDDL `
			-InterfaceType $DefaultInterface `
			-Description "" |
		Format-RuleOutput
	}
}

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log
