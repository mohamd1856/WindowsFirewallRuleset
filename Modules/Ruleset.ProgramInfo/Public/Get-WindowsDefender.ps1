
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
Get Windows Defender installation information

.DESCRIPTION
Gets Windows defender install location directory

.PARAMETER Domain
Computer name for which to list installed Windows Defender

.EXAMPLE
PS> Get-WindowsDefender

.EXAMPLE
PS> Get-WindowsDefender Server01

.INPUTS
None. You cannot pipe objects to Get-WindowsDefender

.OUTPUTS
[PSCustomObject] for installed Windows Defender, version and install paths

.NOTES
None.
#>
function Get-WindowsDefender
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-WindowsDefender.md")]
	[OutputType("Ruleset.ProgramInfo", [void])]
	param (
		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	$Domain = Format-ComputerName $Domain

	if (Test-Computer $Domain)
	{
		$HKLM = "SOFTWARE\Microsoft\Windows Defender"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$LocalRights = [System.Security.AccessControl.RegistryRights]::QueryValues

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer '$Domain'"
			# MSDN: In order for a key to be opened remotely, both the server and client machines
			# must be running the remote registry service, and have remote administration enabled.
			$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain, $RegistryView)

			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:\$HKLM"
			$RootKey = $RemoteKey.OpenSubkey($HKLM, $RegistryPermission, $LocalRights)

			if (!$RootKey)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] The following registry key does not exist '$HKLM'"
				$RemoteKey.Dispose()
				return
			}
		}
		catch
		{
			if ($RemoteKey)
			{
				$RemoteKey.Dispose()
			}

			Write-Error -ErrorRecord $_
			return
		}

		$RootKeyLeaf = Split-Path $RootKey.ToString() -Leaf
		$InstallLocation = $RootKey.GetValue("InstallLocation")

		if ([string]::IsNullOrEmpty($InstallLocation))
		{
			Write-Warning -Message "[$($MyInvocation.InvocationName)] Failed to read registry key entry: $RootKeyLeaf\InstallLocation"
		}
		else
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key '$RootKeyLeaf'"

			[PSCustomObject]@{
				Domain = $Domain
				Name = "Windows Defender"
				Version = (Split-Path $InstallLocation -Leaf)
				Publisher = "Microsoft Corporation"
				InstallLocation = Format-Path $InstallLocation
				RegistryKey = $RootKey.ToString() -replace "HKEY_LOCAL_MACHINE", "HKLM:"
				PSTypeName = "Ruleset.ProgramInfo"
			}
		}

		# MSDN: When you have finished using the type, you should dispose of it either directly or indirectly.
		# To dispose of the type directly, call its Dispose method in a try/catch block.
		# TODO: To dispose of it indirectly, use a language construct such as using (in C#)
		$RemoteKey.Dispose()
	}
}
