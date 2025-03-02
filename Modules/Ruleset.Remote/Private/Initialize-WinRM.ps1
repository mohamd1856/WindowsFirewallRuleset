
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
Initialize WinRM service

.DESCRIPTION
Initialize-WinRM starts the WinRM service, Windows Remote Management (WS-Management) and sets it to
automatic startup.
Adds required firewall rules to be able to configure service options.

.EXAMPLE
PS> Initialize-WinRM

.INPUTS
None. You cannot pipe objects to Initialize-WinRM

.OUTPUTS
None. Initialize-WinRM does not generate any output

.NOTES
None.
#>
function Initialize-WinRM
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
	[OutputType([void])]
	param ()

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	. $PSScriptRoot\..\Scripts\WinRMSettings.ps1

	# NOTE: "Windows Remote Management" predefined rules (including compatibility rules) if not
	# present may cause issues adjusting some of the WinRM options
	# TODO: This will not work if GPO firewall is active and dropping persistent store rules
	if ($PSCmdlet.ShouldProcess("Windows firewall - persistent store", "Check 'Windows Remote Management' rules"))
	{
		if (!(Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore -EA Ignore))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding 'Windows Remote Management' firewall rules"

			# NOTE: Piping to Copy-NetFirewallRule (CimInstance) possible but change not saved
			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMRules `
				-Direction Inbound -NewPolicyStore PersistentStore
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Modifying 'Windows Remote Management' firewall rules"

		Get-NetFirewallRule -Group $WinRMRules -PolicyStore PersistentStore -Direction Inbound |
		# NOTE: Adding custom ports, by default only default HTTP is set
		Set-NetFirewallRule -RemoteAddress Any -Enabled True -LocalPort $PortOptions["HTTP"], $PortOptions["HTTPS"]
	}

	if ($PSCmdlet.ShouldProcess("Windows firewall - persistent store", "Check 'Windows Remote Management - Compatibility Mode' rules"))
	{
		if (!(Get-NetFirewallRule -Group $WinRMCompatibilityRules -PolicyStore PersistentStore -EA Ignore))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Adding 'Windows Remote Management - Compatibility Mode' firewall rules"

			Copy-NetFirewallRule -PolicyStore SystemDefaults -Group $WinRMCompatibilityRules `
				-Direction Inbound -NewPolicyStore PersistentStore
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Modifying 'Windows Remote Management - Compatibility Mode' firewall rules"

		Get-NetFirewallRule -Group $WinRMCompatibilityRules -PolicyStore PersistentStore -Direction Inbound |
		Set-NetFirewallRule -RemoteAddress Any -Enabled True
	}

	if ($PSCmdlet.ShouldProcess("Windows services", "Enable and start WS-Management (WinRM) service"))
	{
		$WinRM = Get-Service -Name WinRM
		# NOTE: Handled by Initialize-Service, but in other functions within module service may be left in unknown state
		if ($WinRM.StartType -ne [ServiceStartMode]::Automatic)
		{
			if ($PSCmdlet.ShouldProcess($WinRM.DisplayName, "Set service to automatic startup"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting $($WinRM.DisplayName) service to automatic startup"
				# TODO: Will not set it to automatic in some cases, ex. when Reset-WinRM is called,
				# see todo for WinRM variable in psm1 module file why
				Set-Service -InputObject $WinRM -StartupType Automatic
			}
		}

		if ($WinRM.Status -ne [ServiceControllerStatus]::Running)
		{
			if ($PSCmdlet.ShouldProcess($WinRM.DisplayName, "Start service"))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Starting $($WinRM.DisplayName) service"
				$WinRM.Start()
				$WinRM.WaitForStatus([ServiceControllerStatus]::Running, $ServiceTimeout)
			}
		}
	}
}
