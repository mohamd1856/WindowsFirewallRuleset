
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2022, 2023 metablaster zebal@protonmail.ch

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
Initialize connection for firewall deployment

.DESCRIPTION
Initialize-Connection configures PowerShell for remote firewall deployment.
CIM session, PS session, remote registry etc.

.PARAMETER Force
The description of Force parameter.

.EXAMPLE
PS> Initialize-Connection

.INPUTS
None. You cannot pipe objects to Initialize-Connection

.OUTPUTS
None. Initialize-Connection does not generate any output

.NOTES
None.

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Connection.md
#>
function Initialize-Connection
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium", PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Initialize/Help/en-US/Initialize-Connection.md")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$ErrorActionPreference = "Stop"
	if ($PSCmdlet.ShouldProcess($PolicyStore, "Connect to WinRM service and enable remote registry"))
	{
		if (Get-Variable -Name SessionEstablished -Scope Global -ErrorAction Ignore)
		{
			# This may happen when remote host comes offline
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Verifying connection status to '$PolicyStore'"
			if (($SessionInstance.State -ne "Opened") -or (!$CimServer.TestConnection()))
			{
				# TODO: We should remove broken sessions and renew them
				Write-Error -Category ConnectionError -TargetObject $PolicyStore `
					-Message "Connection to $PolicyStore is broken, please restart PowerShell and try again"
			}

			return
		}

		Write-Debug -Message "[$($MyInvocation.InvocationName)] Establishing session to remote computer"
		# NOTE: Global object RemoteRegistry (PSDrive), RemoteCim (CimSession) and RemoteSession (PSSession) are created by Connect-Computer function
		# NOTE: Global variable CimServer is set by Connect-Computer function
		# Destruction of these is done by Disconnect-Computer

		# If using Microsoft account for local deployment, credentials are required which in turn require appropriate authentication method
		if (($PolicyStore -in $LocalStore) -and ([System.Security.Principal.WindowsIdentity]::GetCurrent().AuthenticationType -eq "CloudAP"))
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if authentication method is valid for Microsoft account"
			if ($RemotingAuthentication -notin $AuthRequiresCredentials)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Specified authentication method '$RemotingAuthentication' was replaced with 'Negotiate'"
				Set-Variable -Name RemotingAuthentication -Scope Global -Force -Value "Negotiate"
			}
		}

		$ConnectParams = @{
			ErrorAction = "Stop"
			Domain = $PolicyStore
			Protocol = $RemotingProtocol
			ApplicationName = $PSSessionApplicationName
			Authentication = $RemotingAuthentication
		}

		# [System.Management.Automation.Remoting.PSSessionOption]
		# Advanced options for a user-managed remote session
		# TODO: More options are available with New-PSSessionOption
		$PSSessionOption.Culture = $DefaultCulture
		$PSSessionOption.UICulture = $DefaultUICulture
		# OpenTimeout (in milliseconds), affects only PS sessions
		# Determines how long the client computer waits for the session connection to be established.
		# The default value is 180000 (3 minutes). A value of 0 (zero) means no time-out.
		$PSSessionOption.OpenTimeout = 10000
		# CancelTimeout (in milliseconds), affects only PS sessions
		# Determines how long PowerShell waits for a cancel operation (CTRL+C) to finish before ending it.
		# The default value is 60000 (one minute). A value of 0 (zero) means no time-out.
		$PSSessionOption.CancelTimeout = 5000
		# OperationTimeout (in milliseconds), affects both the PS and CIM sessions.
		# The maximum time that any operation in the session can run.
		# When the interval expires, the operation fails.
		# The default value is 180000 (3 minutes). A value of 0 (zero) means no time-out for PS sessions,
		# for CIM sessions it means use the default timeout value for the server (usually 3 minutes)
		$PSSessionOption.OperationTimeout = 120000
		# MaxConnectionRetryCount, affects PS session, Test-NetConnection and Invoke-WebRequest
		# Specifies count of attempts to make a connection to a target host if the current attempt
		# fails due to network issues.
		# The default value is 5 for PS session.
		# The default value is 4 for Test-NetConnection which specifies echo requests
		$PSSessionOption.MaxConnectionRetryCount = 4

		if (($PolicyStore -notin $LocalStore) -or ($RemotingAuthentication -in $AuthRequiresCredentials))
		{
			Set-Variable -Name RemotingCredential -Scope Global -Force -Value (
				Get-Credential -Message "Administrator credentials are required to access '$PolicyStore' computer"
			)

			if (!$RemotingCredential)
			{
				# Will happen if credential request was dismissed using ESC key or by pressing Cancel.
				Write-Error -Category InvalidOperation -TargetObject $PolicyStore `
					-Message "Administrator credentials are required for remote session to '$PolicyStore' computer"
				return
			}
			# Will happen when no password is specified
			elseif ($RemotingCredential.Password.Length -eq 0)
			{
				if (($PolicyStore -in $LocalStore) -and (Test-Credential -User $RemotingCredential -Local))
				{
					Write-Warning -Message "[$($MyInvocation.InvocationName)] User $($RemotingCredential.UserName) has no password set on local computer"
				}

				$UserName = $RemotingCredential.UserName
				Set-Variable -Name RemotingCredential -Scope Global -Force -Value $null
				Write-Error -Category InvalidData -TargetObject $UserName -Message "User '$UserName' must have a password"
				return
			}

			$ConnectParams["Credential"] = $RemotingCredential
		}

		$ConnectionStatus = $false

		$WinRMClientParams = @{
			Confirm = $false
		}

		if ($PolicyStore -notin $LocalStore)
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Establishing session to remote computer"

			$PSSessionOption.NoCompression = $false
			# MSDN: Specifies the default session configuration that is used for PSSessions created in the current session.
			# The default value http://schemas.microsoft.com/PowerShell/microsoft.PowerShell indicates
			# the "Microsoft.PowerShell" session configuration on the remote computer.
			# If you specify only a configuration name, the following schema URI is prepended:
			# http://schemas.microsoft.com/PowerShell/
			$PSSessionConfigurationName = "RemoteFirewall.$($PSVersionTable.PSEdition)"
			$ConnectParams["ConfigurationName"] = $PSSessionConfigurationName

			if ($RemotingProtocol -eq "HTTP")
			{
				$PSSessionOption.NoEncryption = $true
				$ConnectParams["CimOptions"] = New-CimSessionOption -Protocol Wsman -UICulture $DefaultUICulture -Culture $DefaultCulture
			}
			else
			{
				# TODO: fallback to HTTP not implemented
				$PSSessionOption.NoEncryption = $false
				# TODO: Encoding, the acceptable values for this parameter are: Default, Utf8, or Utf16
				# There is global variable which controls encoding, see if it can be used here
				$ConnectParams["CimOptions"] = New-CimSessionOption -UseSsl -Encoding "Default" -UICulture $DefaultUICulture -Culture $DefaultCulture
			}

			# If Set-WinRMClient is run during loopback testing then it doesn't need to run during remote testing
			$WinRMClientSet = $false

			if (![string]::IsNullOrEmpty($SslThumbprint))
			{
				$WinRMClientParams.CertThumbprint = $SslThumbprint
			}

			if ($PSVersionTable.PSEdition -eq "Core")
			{
				# TODO: Loopback WinRM is required for Ruleset.Compatibility module for testing and local session?
				# Compatibility session will also run on remote computer due to startup script which
				# loads Ruleset.ProgramInfo which in turn calls Import-WinModule which creates compatibility session
				# need to see if compatibility session on remote session is needed
				# TODO: This test should be against Microsoft.PowreShell configuration but it is not accessible from Core
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if loopback WinRM requires configuration..."
				# TODO: If this test succeeds there is no quarantee client is set for HTTPS
				Test-WinRM -Protocol HTTP -Status ([ref] $ConnectionStatus) -Quiet -ConfigurationName "LocalFirewall.$($PSVersionTable.PSEdition)"

				if (!$ConnectionStatus)
				{
					# Set client by the way for both, loopback HTTP and remote HTTPS,
					# this is also needed to be able to Test-WinRM on loopback
					if ($RemotingProtocol -eq "HTTP")
					{
						Set-WinRMClient -Domain $PolicyStore -TrustedHosts $PolicyStore @WinRMClientParams
					}
					else
					{
						Set-WinRMClient -Domain $PolicyStore @WinRMClientParams
					}

					# Enable loopback only HTTP
					Enable-WinRMServer -Protocol HTTP -KeepDefault -Loopback -Confirm:$false
					Test-WinRM -Protocol HTTP -ErrorAction Stop -ConfigurationName "LocalFirewall.$($PSVersionTable.PSEdition)"
					$WinRMClientSet = $true
				}
			}

			$TestParams = @{
				Domain = $PolicyStore
				Protocol = $RemotingProtocol
				Credential = $RemotingCredential
				ConfigurationName = $PSSessionConfigurationName
			}

			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if remoting WinRM requires configuration..."
			$ConnectionStatus = $false
			Test-WinRM @TestParams -Status ([ref] $ConnectionStatus) -Quiet

			# TODO: A new function needed to conditionally configure remote host here
			if (!$ConnectionStatus)
			{
				# If using PS Core it's already set above
				if (!$WinRMClientSet)
				{
					# Configure this machine for remote session over SSL
					if ($RemotingProtocol -eq "HTTP")
					{
						Set-WinRMClient -Domain $PolicyStore -TrustedHosts $PolicyStore @WinRMClientParams
					}
					else
					{
						Set-WinRMClient -Domain $PolicyStore @WinRMClientParams
					}
				}

				# HACK: This will fail in PS Core if remote server is set as HTTPS only because
				# compatibility module in remote session will attempt to cotact "localhost" or the
				# server which doesn't listen to HTTP
				# A workaround is to set remote host to listen on both HTTP and HTTPS
				# TODO: Desired solution is to configure remote server so that is listens on HTTPS
				# on all addresses and HTTP only loopback for compatibility session
				Test-WinRM @TestParams -ErrorAction Stop
			}
		}
		# localhost and . are converted in ProjectSettings
		elseif ($PolicyStore -eq [System.Environment]::MachineName)
		{
			$PSSessionOption.NoEncryption = $true
			$PSSessionOption.NoCompression = $true
			$PSSessionConfigurationName = "LocalFirewall.$($PSVersionTable.PSEdition)"

			$TestParams = @{
				ConfigurationName = $PSSessionConfigurationName
			}

			if ($RemotingAuthentication -in $AuthRequiresCredentials)
			{
				$TestParams["Credential"] = $RemotingCredential
			}

			# For loopback using only HTTP
			# TODO: For completeness, implement use of HTTPS, credentials will be needed
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Establishing session to local computer"
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if loopback WinRM requires configuration..."
			Test-WinRM -Protocol HTTP -Status ([ref] $ConnectionStatus) -Quiet @TestParams

			if (!$ConnectionStatus)
			{
				# Enable loopback only HTTP
				Set-WinRMClient -Protocol HTTP @WinRMClientParams
				Enable-WinRMServer -Protocol HTTP -KeepDefault -Loopback -Confirm:$false
				Test-WinRM -Protocol HTTP @TestParams -ErrorAction Stop
			}

			$ConnectParams["Protocol"] = "HTTP"
			$ConnectParams["ConfigurationName"] = $PSSessionConfigurationName
			$ConnectParams["CimOptions"] = New-CimSessionOption -Protocol Wsman -UICulture $DefaultUICulture -Culture $DefaultCulture
		}
		else
		{
			Write-Error -Category NotImplemented -TargetObject $PolicyStore `
				-Message "Deployment to specified policy store not implemented '$PolicyStore'"
			return
		}

		try
		{
			Connect-Computer @ConnectParams

			if ($PolicyStore -notin $LocalStore)
			{
				Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Checking if remote registry requires configuration..."

				if (!(Test-RemoteRegistry -Domain $PolicyStore -Quiet))
				{
					Enable-RemoteRegistry -Confirm:$false
					Test-RemoteRegistry -Domain $PolicyStore | Out-Null
				}
			}
		}
		catch
		{
			Write-Error -ErrorRecord $_
		}
	}
}
