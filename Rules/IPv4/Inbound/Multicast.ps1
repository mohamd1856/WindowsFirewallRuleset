
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
Inbound IPv4 multicast rules

.DESCRIPTION
Inbound firewall rules for IPv4 multicast address Space

.PARAMETER Domain
Computer name onto which to deploy rules

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Multicast.ps1

.INPUTS
None. You cannot pipe objects to Multicast.ps1

.OUTPUTS
None. Multicast.ps1 does not generate any output

.NOTES
NOTE: Boot time multicast dropped due to WFP Operation (Windows Filtering Platform), the transition from
boot-time to persistent filters could be several seconds, or even longer on a slow machine.

Address Range					Size		CIDR				Designation
-------------					----		-----------			-----------
224.0.0.0 - 224.0.0.255			(/24)		224.0.0/24			Local Network Control Block
224.0.1.0 - 224.0.1.255			(/24)		224.0.1/24			Internetwork Control Block
224.0.2.0 - 224.0.255.255		(65024)							AD-HOC Block I
224.1.0.0 - 224.1.255.255		(/16)		224.1/16			RESERVED
224.2.0.0 - 224.2.255.255		(/16)		224.2/16			SDP/SAP Block
224.3.0.0 - 224.4.255.255		(2 /16s)	224.3/16, 224.4/16	AD-HOC Block II
224.5.0.0 - 224.255.255.255		(251 /16s)	251 /16s			RESERVED
224.252.0.0 - 224.255.255.255	(/14)		224.252/14			DIS Transient Groups
225.0.0.0 - 231.255.255.255		(7 /8s)		7 /8s				RESERVED
232.0.0.0 - 232.255.255.255		(/8)		232/8				Source-Specific Multicast Block
233.0.0.0 - 233.251.255.255		(16515072)						GLOP Block
233.252.0.0 - 233.255.255.255	(/14)		233.252/14			AD-HOC Block III
234.0.0.0 - 234.255.255.255		()								Unicast-Prefix-based IPv4 Multicast Addresses
235.0.0.0 - 238.255.255.255		()								Scoped Multicast Ranges (RESERVED)
239.0.0.0 - 239.255.255.255		(/8)							Scoped Multicast Ranges (Organization-Local Scope) aka Administratively Scoped Block.

.LINK
https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml
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
. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 $PSCmdlet -Domain $Domain
Initialize-Project
. $PSScriptRoot\DirectionSetup.ps1

Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Multicast - IPv4"
# NOTE: Unlike with IPv6 multicast we can afford excluding "Public" profile since there aren't
# as many different multicast addresses
# TODO: We should exclude public profile conditionally when not essential (ex. no homegroup required)
$LocalProfile = "Any" #"Private, Domain"
$MulticastUsers = Get-SDDL -Domain "NT AUTHORITY" -User "LOCAL SERVICE", "NETWORK SERVICE" -Merge
# Users group is needed to handle program specific traffic, ex. MS edge 1900
Merge-SDDL ([ref] $MulticastUsers) -From $UsersGroupSDDL
$Accept = "Inbound rules for IPv4 multicast will be loaded, recommended for proper network functioning"
$Deny = "Skip operation, inbound IPv4 multicast rules will not be loaded into firewall"
if (!(Approve-Execute -Accept $Accept -Deny $Deny -ContextLeaf $Group -Force:$Force)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# IPv4 Multicast Address Space
#

New-NetFirewallRule -DisplayName "Local Network Control Block" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 224.0.0.0-224.0.0.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Addresses in the Local Network Control Block are used for protocol control
traffic that is not forwarded off link.
Examples of this type of use include OSPFIGP All Routers (224.0.0.5)." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Internetwork Control Block" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 224.0.1.0-224.0.1.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Addresses in the Internetwork Control Block are used for protocol
control traffic that MAY be forwarded through the Internet. Examples
include 224.0.1.1 (Network Time Protocol (NTP)) and 224.0.1.68 (mdhcpdiscover)." | Format-RuleOutput

New-NetFirewallRule -DisplayName "AD-HOC Block I" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 224.0.2.0-224.0.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Addresses in the AD-HOC blocks were
traditionally used for assignments for those applications that don't fit in either the Local or
Internetwork Control blocks.
These addresses MAY be globally routed and are typically used by applications that require small
blocks of addressing (e.g., less than a /24 ).
Future assignments of blocks of addresses that do not fit in the Local Network or Internetwork
Control blocks will be made in AD-HOC Block III." | Format-RuleOutput

New-NetFirewallRule -DisplayName "SDP/SAP Block" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 224.2.0.0-224.2.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Addresses in the SDP/SAP Block are used by applications that receive addresses
through the Session Announcement Protocol for use via applications like the session directory tool
(such as [SDR])." | Format-RuleOutput

New-NetFirewallRule -DisplayName "AD-HOC Block II" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 224.3.0.0-224.4.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Addresses in the AD-HOC blocks were
traditionally used for assignments for those applications that don't fit in either the Local or
Internetwork Control blocks.
These addresses MAY be globally routed and are typically used by applications that require small
blocks of addressing (e.g., less than a /24 ).
Future assignments of blocks of addresses that do not fit in the Local Network or Internetwork
Control blocks will be made in AD-HOC Block III." | Format-RuleOutput

New-NetFirewallRule -DisplayName "DIS Transient Groups" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 224.252.0.0-224.255.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "The statically assigned link-local scope is 224.0.0.0/24." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Source-Specific Multicast Block" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 232.0.0.0-232.255.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "SSM is an extension of IP Multicast in which traffic is forwarded to receivers
from only those multicast sources for which the receivers have explicitly expressed interest and is
primarily targeted at one-to-many (broadcast) applications.
Note that this block was initially assigned to the Versatile Message Transaction Protocol (VMTP)
transient groups [IANA]." | Format-RuleOutput

New-NetFirewallRule -DisplayName "GLOP Block" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 233.0.0.0-233.251.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Addresses in the GLOP Block are globally-scoped, statically-assigned addresses.
The assignment is made, for a domain with a 16-bit Autonomous System Number (ASN), by mapping a
domain's autonomous system number, expressed in octets as X.Y, into the middle two octets of the
GLOP Block, yielding an assignment of 233.X.Y.0/24.
The mapping and assignment is defined in [RFC3180].
Domains with a 32-bit ASN MAY apply for space in AD-HOC Block III, or consider using IPv6 multicast
addresses." | Format-RuleOutput

New-NetFirewallRule -DisplayName "AD-HOC Block III" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 233.252.0.0-233.255.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "[RFC3138] delegated to the RIRs the assignment of the GLOP sub-block mapped by
the private Autonomous System (AS) space (64512-65534) and the IANA reserved ASN 65535.
This space was known as Extended GLOP (EGLOP).
RFC 3138 should not have asked the RIRs to develop policies for the EGLOP space because [RFC2860]
reserves that to the IETF.
It is important to make this space available for use by network operators,
and it is therefore appropriate to obsolete RFC 3138 and classify this address range as available
for AD-HOC assignment." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Unicast-Prefix-based IPv4 Multicast Addresses" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled False -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 234.0.0.0-234.255.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "This specification defines an extension to the multicast addressing architecture
of the IP Version 4 protocol.
The extension presented in this document allows for unicast-prefix-based assignment of multicast addresses.
By delegating multicast addresses at the same time as unicast prefixes, network operators will be
able to identify their multicast addresses without needing to run an inter-domain
allocation protocol." | Format-RuleOutput

New-NetFirewallRule -DisplayName "Administratively Scoped Block" `
	-Platform $Platform -PolicyStore $PolicyStore -Profile $LocalProfile `
	-Service Any -Program Any -Group $Group `
	-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
	-LocalAddress 239.0.0.0-239.255.255.255 -RemoteAddress Any `
	-LocalPort Any -RemotePort Any `
	-LocalUser $MulticastUsers -EdgeTraversalPolicy Block `
	-InterfaceType $DefaultInterface `
	-LocalOnlyMapping $false -LooseSourceMapping $false `
	-Description "Addresses in the Administratively Scoped Block are for local use within a domain." |
Format-RuleOutput

if ($UpdateGPO)
{
	Invoke-Process gpupdate.exe
	Disconnect-Computer -Domain $Domain
}

Update-Log
