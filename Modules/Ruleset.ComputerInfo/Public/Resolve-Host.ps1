
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
Resolve host to IP or IP to host

.DESCRIPTION
Resolve host name to IP address or IP address to host name.
For localhost process virtual or hidden, connected or disconnected adapter address.
By default only physical adapters are processed

.PARAMETER Domain
Target host name which to resolve to IP address

.PARAMETER IPAddress
Target IP which to resolve to host name

.PARAMETER FlushDNS
Flush DNS resolver cache before resolving IP or host name

.PARAMETER AddressFamily
Obtain IP address for the specified IP version

.PARAMETER Physical
Resolve local host name to IP of any physical adapter

.PARAMETER Virtual
Resolve local host name to IP of any virtual adapter

.PARAMETER Connected
If specified, only interfaces connected to network are considered

.EXAMPLE
PS> Resolve-Host -AddressFamily IPv4 -IPAddress "40.112.72.205"

.EXAMPLE
PS> Resolve-Host -FlushDNS -Domain "microsoft.com"

.EXAMPLE
PS> Resolve-Host -AddressFamily IPv4 -Connected

.INPUTS
[IPAddress[]]
[string[]]

.OUTPUTS
[PSCustomObject]

.NOTES
TODO: Single IP is selected for result, maybe we should return all IP addresses
TODO: AddressFamily could be 2 switches, -IPv4 and IPv6
#>
function Resolve-Host
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Physical", SupportsShouldProcess = $true,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Resolve-Host.md")]
	[OutputType("Ruleset.HostInfo")]
	param (
		[Parameter(ParameterSetName = "Host", Mandatory = $true,
			HelpMessage = "Enter host name which is to be resolved",
			ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("ComputerName", "CN")]
		[string[]] $Domain,

		[Parameter(ParameterSetName = "IP", Mandatory = $true,
			HelpMessage = "Enter IP address which is to be resolved",
			ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[IPAddress[]] $IPAddress,

		[Parameter(ParameterSetName = "Host")]
		[Parameter(ParameterSetName = "IP")]
		[switch] $FlushDNS,

		[Parameter(ParameterSetName = "Host")]
		[Parameter(ParameterSetName = "Physical")]
		[Parameter(ParameterSetName = "Virtual")]
		[Alias("IPVersion")]
		[ValidateSet("IPv4", "IPv6", "Any")]
		[string] $AddressFamily = "Any",

		[Parameter(ParameterSetName = "Physical")]
		[switch] $Physical,

		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Virtual,

		[Parameter(ParameterSetName = "Physical")]
		[Parameter(ParameterSetName = "Virtual")]
		[switch] $Connected
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	}
	process
	{
		if ($FlushDNS)
		{
			# TODO: Should this be called only once for pipelines?
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Flushing DNS resolver cache"
			Clear-DnsClientCache
		}

		if ($IPAddress)
		{
			foreach ($IP in $IPAddress)
			{
				[string] $HostName = $null

				try
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Resolving IP '$IP'"
					# https://docs.microsoft.com/en-us/dotnet/api/system.net.dns?view=net-5.0
					[System.Net.IPHostEntry] $HostEntry = [System.Net.Dns]::GetHostEntry($IP)

					$HostName = $HostEntry.HostName
				}
				catch [System.Net.Sockets.SocketException]
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Socket exception resolving address '$IP'"
				}
				catch
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] $($_.Exception.Message)"
				}

				[PSCustomObject] @{
					Domain = $HostName
					IPAddress = $IP
					PSTypeName = "Ruleset.HostInfo"
				}
			}
		}
		elseif ($Domain)
		{
			foreach ($Computer in $Domain)
			{
				[IPAddress] $IP = $null
				[regex] $IPv4Regex = "([0-9]{1,3}\.){3}[0-9]{1,3}"
				[regex] $IPv6Regex = "([a-f0-9:]+:)+[a-f0-9]+"

				# TODO: Assuming IPv4 connectivity and single interface connected to network
				$DnsServer = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses

				try
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Resolving host '$Computer' to '$AddressFamily' address"

					foreach ($ServerAddress in $DnsServer)
					{
						Write-Debug -Message "[$($MyInvocation.InvocationName)] Using DNS server address $ServerAddress"

						# [Microsoft.DnsClient.Commands.DnsRecord]
						$DnsRecord = Resolve-DnsName -Name $Computer -NetbiosFallback -Server $ServerAddress -EA Stop
						$DnsRecord_TXT = $DnsRecord | Select-Object -Property IPAddress

						if ($DnsRecord_TXT)
						{
							if ($AddressFamily -eq "IPv4")
							{
								$Match = $IPv4Regex.Matches($DnsRecord_TXT.IPAddress)
								if ($Match.Success)
								{
									$IP = $Match.Captures[0] | Select-Object -ExpandProperty Value
								}
							}
							elseif ($AddressFamily -eq "IPv6")
							{
								# TODO: This needs testing with IPv6
								$Match = $IPv6Regex.Matches($DnsRecord_TXT.IPAddress)
								if ($Match.Success)
								{
									$IP = $Match.Captures[0] | Select-Object -ExpandProperty Value
								}
							}
							else
							{
								for ($Index = 0; $Index -lt $DnsRecord_TXT.Length; ++$Index)
								{
									$IP = $DnsRecord_TXT[$Index].IPAddress
									if ($null -ne $IP) { break }
								}
							}

							break
						}
					}
				}
				catch
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] $($_.Exception.Message)"
				}

				if (!$IP)
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] Unable to resolve host '$Computer'"
				}

				[PSCustomObject] @{
					Domain = $Computer
					IPAddress = $IP | Select-Object -ExpandProperty IPAddressToString
					PSTypeName = "Ruleset.HostInfo"
				}
			} # foreach $Computer
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Getting localhost '$AddressFamily' address for domain '$([System.Environment]::MachineName)'"

			[IPAddress] $IP = $null

			if ($Virtual -and !$Physical)
			{
				$ConfiguredInterfaces = Select-IPInterface -AddressFamily:$AddressFamily -Connected:$Connected -Virtual
			}
			elseif ($Physical -and !$Virtual)
			{
				$ConfiguredInterfaces = Select-IPInterface -AddressFamily:$AddressFamily -Connected:$Connected -Physical
			}
			else
			{
				$ConfiguredInterfaces = Select-IPInterface -AddressFamily:$AddressFamily -Connected:$Connected
			}

			if ($ConfiguredInterfaces)
			{
				if ($AddressFamily -eq "Any")
				{
					# Microsoft.Management.Infrastructure.CimInstance#root/StandardCimv2/MSFT_NetIPAddress
					$NetIPAddress = $ConfiguredInterfaces | Select-Object -ExpandProperty ("IPv4Address")

					if (!$NetIPAddress)
					{
						$NetIPAddress = $ConfiguredInterfaces | Select-Object -ExpandProperty ("IPv6Address")
					}
				}
				else
				{
					$NetIPAddress = $ConfiguredInterfaces | Select-Object -ExpandProperty ($AddressFamily + "Address")
				}

				$IP = $NetIPAddress | Select-Object -ExpandProperty IPAddress -First 1
			}

			[PSCustomObject] @{
				Domain = [System.Environment]::MachineName
				IPAddress = $IP
				PSTypeName = "Ruleset.HostInfo"
			}
		}
	}
}
