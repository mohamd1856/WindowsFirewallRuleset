
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

<#PSScriptInfo

.VERSION 0.15.0

.GUID cd8db1a8-63cd-443d-bdab-baf91b787fe9

.AUTHOR metablaster zebal@protonmail.com

.REQUIREDSCRIPTS ProjectSettings.ps1

.EXTERNALMODULEDEPENDENCIES Ruleset.Logging, Ruleset.Initialize, Ruleset.Utility
#>

<#
.SYNOPSIS
Conclude firewall deployment

.DESCRIPTION
Conclude firewall deployment by setting private, domain and public firewall profile,
default network adapter profile and global firewall behavior settings.
Also update target GPO for changes to take effect.

.PARAMETER Domain
Computer name on which to conclude deployment

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> Complete-Firewall

.EXAMPLE
PS> Complete-Firewall -Force

.INPUTS
None. You cannot pipe objects to Complete-Firewall.ps1

.OUTPUTS
None. Complete-Firewall.ps1 does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Scripts/README.md
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
[OutputType([void])]
param (
	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Write-Debug -Message "[$ThisScript] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
Initialize-Project

# User prompt
$Accept = "Configure and enable GPO firewall and global firewall behavior on '$Domain' computer"
$Deny = "Skip operation, no change will be done to firewall or network profile on '$Domain' computer"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

#
# TODO: it looks like private profile traffic is logged into public log and vice versa
# Confirm this happens on VM default switch only which operates on public profile somehow
#

# NOTE: Reducing the default (4096 KB) log file size makes logs appear quicker but consumes more resources
# MSDN: LogMaxSizeKilobytes, NotConfigured: Valid only when configuring a Group Policy Object (GPO)
# This parameter values is case sensitive and NotConfigured can only be specified using dot-notation.
# The default setting when managing a computer is 4096
# When managing a GPO, the default setting is NotConfigured.
$LogSize = 1024

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags $ThisScript -MessageData "INFO: Setting up public firewall profile on '$Domain' computer..."

Set-NetFirewallProfile -Profile Public -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast False `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes $LogSize `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "$FirewallLogsFolder\PublicFirewall.log" -DisabledInterfaceAliases @(
	# Exclude interfaces for public profile here
)

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags $ThisScript -MessageData "INFO: Setting up private firewall profile on '$Domain' computer..."

Set-NetFirewallProfile -Profile Private -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast True `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes $LogSize `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "$FirewallLogsFolder\PrivateFirewall.log" -DisabledInterfaceAliases @(
	# Exclude interfaces for private profile here
)

# Setting up profile seem to be slow, tell user what is going on
Write-Information -Tags $ThisScript -MessageData "INFO: Setting up domain firewall profile on '$Domain' computer..."

Set-NetFirewallProfile -Profile Domain -PolicyStore $PolicyStore `
	-Enabled True -DefaultInboundAction Block -DefaultOutboundAction Block -AllowInboundRules True `
	-AllowLocalFirewallRules False -AllowLocalIPsecRules False `
	-NotifyOnListen True -EnableStealthModeForIPsec True -AllowUnicastResponseToMulticast True `
	-LogAllowed False -LogBlocked True -LogIgnored True -LogMaxSizeKilobytes $LogSize `
	-AllowUserApps NotConfigured -AllowUserPorts NotConfigured `
	-LogFileName "$FirewallLogsFolder\DomainFirewall.log" -DisabledInterfaceAliases @(
	# Exclude interfaces for domain profile here
)

Write-Information -Tags $ThisScript -MessageData "INFO: Setting up global firewall settings on '$Domain' computer..."

# Modify the global firewall settings of the target computer.
# Configures properties that apply to the firewall and IPsec settings,
# regardless of which network profile is currently in use.
# MSDN: MaxSAIdleTimeSeconds, NotConfigured: Valid only when configuring a Group Policy Object (GPO)
# This parameter values is case sensitive and NotConfigured can only be specified using dot-notation.
# The default value when managing a local computer is 300 seconds (5 minutes).
# When managing a GPO, the default value is NotConfigured.
# TODO: Set and reset settings found in IPSec tab, see NetSecurity module
Set-NetFirewallSetting -PolicyStore $PolicyStore `
	-EnableStatefulFtp True -EnableStatefulPptp False -EnablePacketQueuing NotConfigured `
	-Exemptions None -CertValidationLevel RequireCrlCheck `
	-KeyEncoding UTF8 -RequireFullAuthSupport NotConfigured `
	-MaxSAIdleTimeSeconds 300 -AllowIPsecThroughNAT NotConfigured `
	-RemoteUserTransportAuthorizationList None -RemoteUserTunnelAuthorizationList None `
	-RemoteMachineTransportAuthorizationList None -RemoteMachineTunnelAuthorizationList None `

# Set network profile for adapters of choice
Set-NetworkProfile -Session $SessionInstance

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe -NoNewWindow -ArgumentList "/target:computer" -Session $SessionInstance
	Disconnect-Computer -Domain $Domain
}

Update-Log
