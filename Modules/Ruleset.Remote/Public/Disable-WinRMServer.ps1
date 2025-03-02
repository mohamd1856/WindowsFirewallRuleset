
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2021-2023 metablaster zebal@protonmail.ch

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

using namespace System.ServiceProcess

<#
.SYNOPSIS
Disable WinRM server for CIM and PowerShell remoting

.DESCRIPTION
Disable WinRM server for remoting previously enabled by Enable-WinRMServer.
WinRM service will continue to run but will accept only loopback HTTP and only if
using "LocalFirewall.PSedition" session configuration.

In addition unlike Disable-PSRemoting, it will also remove default firewall rules
and restore registry setting which restricts remote access to members of the
Administrators group on the computer.

.PARAMETER All
If specified, will disable WinRM service completely including loopback functionality,
remove all listeners, disable all session configurations and disable registry setting to
deny remote access to Administrators

.PARAMETER KeepDefault
If specified, keeps default session configurations enabled.
This is needed to be able to specify -ComputerName parameter in commands that support it

.EXAMPLE
PS> Disable-WinRMServer

.EXAMPLE
PS> Disable-WinRMServer -KeepDefault

.EXAMPLE
PS> Disable-WinRMServer -All

.INPUTS
None. You cannot pipe objects to Disable-WinRMServer

.OUTPUTS
None. Disable-WinRMServer does not generate any output

.NOTES
TODO: How to control language? in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error
TODO: Implement -NoServiceRestart parameter if applicable so that only configuration is affected
See also output of: winrm get winrm/config

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-WinRMServer.md

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management

.LINK
https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management

.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations
#>
function Disable-WinRMServer
{
	[CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-WinRMServer.md")]
	[OutputType([void])]
	param (
		[Parameter(ParameterSetName = "All")]
		[switch] $All,

		[Parameter(ParameterSetName = "Default")]
		[switch] $KeepDefault
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	. $PSScriptRoot\..\Scripts\WinRMSettings.ps1 -IncludeServer -AllowUnencrypted:(!$All)

	<# MSDN: Disabling the session configurations does not undo all the changes made by the
	Enable-PSRemoting or Enable-PSSessionConfiguration cmdlet.
	You might have to manually undo the changes by following these steps:
	1. Stop and disable the WinRM service.
	2. Delete the listener that accepts requests on any IP address.
	3. Disable the firewall exceptions for WS-Management communications.
	4. Restore the value of the LocalAccountTokenFilterPolicy to 0, which restricts remote access to
	members of the Administrators group on the computer.
	#>
	if ($All)
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Disabling WinRM remoting and loopback server..."
	}
	else
	{
		Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Disabling WinRM remoting server..."
	}

	Initialize-WinRM

	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Remove all listeners"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing all WinRM server listeners"
		Get-ChildItem WSMan:\localhost\listener | Remove-Item -Recurse
	}

	if ($All)
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable all session configurations"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling all WinRM session configurations"
			Disable-PSSessionConfiguration -Name * -NoServiceRestart -Force
		}
	}
	else
	{
		# NOTE: Do not use Set-PSSessionConfiguration -AccessMode Local because "Remote" access mode is required to create PSSession
		if ($KeepDefault -and $PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable custom session configurations"))
		{
			# Disable all custom session configurations, keep default ones
			# HACK: Using Where-Object for this task will not work with -notlike operator
			foreach ($Session in Get-PSSessionConfiguration)
			{
				$a = $Session.Name -notlike "Microsoft.PowerShell*"
				$b = $Session.Name -notlike "PowerShell.7*"
				$c = $Session.Name -notmatch "(Local|Remote)Firewall\.(Core|Desktop)"

				if ($a -and $b -and $c)
				{
					Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling '$($Session.Name)' custom session configuration"
					Disable-PSSessionConfiguration -NoServiceRestart -Force -Name $Session.Name
				}
			}
		}
		elseif (!$KeepDefault -and $PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable all unneeded session configurations"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling all unneeded session configurations"

			# Disable all session configurations except what's needed for local firewall management and Ruleset.Compatibility module
			Get-PSSessionConfiguration | Where-Object {
				($_.Name -ne "Microsoft.PowerShell") -and
				($_.Name -ne $LocalFirewallSession)
			} | Disable-PSSessionConfiguration -NoServiceRestart -Force
		}

		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure loopback listener"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server loopback listener"

			# Enable only localhost on loopback
			if ($PSVersionTable.PSEdition -eq "Core")
			{
				New-Item -Path WSMan:\localhost\Listener -Address "IP:[::1]" -Transport HTTP -Enabled $true -Force | Out-Null
				New-Item -Path WSMan:\localhost\Listener -Address "IP:127.0.0.1" -Transport HTTP -Enabled $true -Force | Out-Null
			}
			else
			{
				New-WSManInstance -SelectorSet @{ Address = "IP:[::1]"; Transport = "HTTP" } `
					-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null

				New-WSManInstance -SelectorSet @{ Address = "IP:127.0.0.1"; Transport = "HTTP" } `
					-ValueSet @{ Enabled = $true } -ResourceURI winrm/config/Listener | Out-Null
			}
		}

		#
		# The rest of WinRM configuration is to ensure loopback functioning and
		# to revert changes done by Enable-WinRMServer
		#

		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure server authentication options"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server authentication options"

			if ($PSVersionTable.PSEdition -eq "Core")
			{
				Set-Item -Path WSMan:\localhost\service\auth\Kerberos -Value $AuthenticationOptions["Kerberos"]
				Set-Item -Path WSMan:\localhost\service\auth\Certificate -Value $AuthenticationOptions["Certificate"]
				Set-Item -Path WSMan:\localhost\service\auth\Basic -Value $AuthenticationOptions["Basic"]
				Set-Item -Path WSMan:\localhost\service\auth\CredSSP -Value $AuthenticationOptions["CredSSP"]
			}
			else
			{
				Set-WSManInstance -ResourceURI winrm/config/service/auth -ValueSet $AuthenticationOptions | Out-Null
			}
		}

		Unblock-NetProfile

		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure default server ports"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM default server ports"

			if ($PSVersionTable.PSEdition -eq "Core")
			{
				Set-Item -Path WSMan:\localhost\service\DefaultPorts\HTTP -Value $PortOptions["HTTP"]
				Set-Item -Path WSMan:\localhost\service\DefaultPorts\HTTPS -Value $PortOptions["HTTPS"]
			}
			else
			{
				Set-WSManInstance -ResourceURI winrm/config/service/DefaultPorts -ValueSet $PortOptions | Out-Null
			}
		}

		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure server options"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server options"

			if ($PSVersionTable.PSEdition -eq "Core")
			{
				# NOTE: Disable warning which say:
				# The updated configuration might affect the operation of the plugins having a per plugin quota value greater than
				Set-Item -Path WSMan:\localhost\service\MaxConcurrentOperationsPerUser `
					-Value $ServerOptions["MaxConcurrentOperationsPerUser"] -WarningAction SilentlyContinue

				Set-Item -Path WSMan:\localhost\service\EnumerationTimeoutms -Value $ServerOptions["EnumerationTimeoutms"]
				Set-Item -Path WSMan:\localhost\service\MaxConnections -Value $ServerOptions["MaxConnections"]
				Set-Item -Path WSMan:\localhost\service\MaxPacketRetrievalTimeSeconds -Value $ServerOptions["MaxPacketRetrievalTimeSeconds"]
				Set-Item -Path WSMan:\localhost\service\AllowUnencrypted -Value $ServerOptions["AllowUnencrypted"]
				Set-Item -Path WSMan:\localhost\service\IPv4Filter -Value $ServerOptions["IPv4Filter"]
				Set-Item -Path WSMan:\localhost\service\IPv6Filter -Value $ServerOptions["IPv6Filter"]
				Set-Item -Path WSMan:\localhost\service\EnableCompatibilityHttpListener -Value $ServerOptions["EnableCompatibilityHttpListener"]
				Set-Item -Path WSMan:\localhost\service\EnableCompatibilityHttpsListener -Value $ServerOptions["EnableCompatibilityHttpsListener"]
			}
			else
			{
				# NOTE: This will fail if any adapter is on public network, using winrm gives same result:
				# cmd.exe /C 'winrm set winrm/config/service @{MaxConnections=300}'
				Set-WSManInstance -ResourceURI winrm/config/service -ValueSet $ServerOptions | Out-Null
			}
		}

		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Configure protocol options"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRM server protocol options"

			if ($PSVersionTable.PSEdition -eq "Core")
			{
				Set-Item -Path WSMan:\localhost\config\MaxEnvelopeSizekb -Value $ProtocolOptions["MaxEnvelopeSizekb"]
				Set-Item -Path WSMan:\localhost\config\MaxTimeoutms -Value $ProtocolOptions["MaxTimeoutms"]
				Set-Item -Path WSMan:\localhost\config\MaxBatchItems -Value $ProtocolOptions["MaxBatchItems"]
			}
			else
			{
				Set-WSManInstance -ResourceURI winrm/config -ValueSet $ProtocolOptions | Out-Null
			}
		}

		Restore-NetProfile
	} # if not All


	if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Set WinRS options"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Configuring WinRS options"

		if ($PSVersionTable.PSEdition -eq "Core")
		{
			# NOTE: Disable warnings which say:
			# The updated configuration might affect the operation of the plugins having a per plugin quota value greater than
			$PreviousPreference = $WarningPreference
			$WarningPreference = "SilentlyContinue"
			Set-Item -Path WSMan:\localhost\Shell\AllowRemoteShellAccess -Value $WinRSOptions["AllowRemoteShellAccess"]
			Set-Item -Path WSMan:\localhost\Shell\IdleTimeout -Value $WinRSOptions["IdleTimeout"]
			Set-Item -Path WSMan:\localhost\Shell\MaxConcurrentUsers -Value $WinRSOptions["MaxConcurrentUsers"]
			Set-Item -Path WSMan:\localhost\Shell\MaxProcessesPerShell -Value $WinRSOptions["MaxProcessesPerShell"]
			Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value $WinRSOptions["MaxMemoryPerShellMB"]
			Set-Item -Path WSMan:\localhost\Shell\MaxShellsPerUser -Value $WinRSOptions["MaxShellsPerUser"]
			$WarningPreference = $PreviousPreference
		}
		else
		{
			Set-WSManInstance -ResourceURI winrm/config/winrs -ValueSet $WinRSOptions | Out-Null
		}
	}

	# NOTE: This registry key does not affect computers that are members of an Active Directory domain.
	# In this case, Enable-PSRemoting does not create the key,
	# and you don't have to set it to 0 after disabling remoting with Disable-PSRemoting
	if ($All -and !(Get-CimInstance -Class Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain))
	{
		# NOTE: LocalAccountTokenFilterPolicy must be enabled for New-PSSession to work
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Disable registry setting to deny remote access to Administrators"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling remote access to members of the Administrators group"

			# NOTE: The following is set by Enable-PSRemoting, it prevents UAC and
			# allows remote access to members of the Administrators group on the computer.
			Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Value 0 `
				-Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
		}
	}

	if ($PSCmdlet.ShouldProcess("Windows firewall, persistent store", "Remove all WinRM predefined rules"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Removing all default WinRM firewall rules"

		# Remove all WinRM predefined rules
		Remove-NetFirewallRule -Group @($WinRMRules, $WinRMCompatibilityRules) `
			-Direction Inbound -PolicyStore PersistentStore -ErrorAction Ignore
	}

	$WinRM = Get-Service -Name WinRM

	if ($All)
	{
		if ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Stop and disable service"))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Stopping WS-Management (WinRM) service"
			Set-Service -Name WinRM -StartupType Disabled
			$WinRM.Stop()
			$WinRM.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
		}
	}
	elseif ($PSCmdlet.ShouldProcess("WS-Management (WinRM) service", "Restart service"))
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Restarting WS-Management (WinRM) service"

		$WinRM.Stop()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Stopped, $ServiceTimeout)
		$WinRM.Start()
		$WinRM.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Disabling WinRM server completed successfully"
}
