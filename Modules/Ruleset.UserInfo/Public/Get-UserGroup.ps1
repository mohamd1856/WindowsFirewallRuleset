
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
Get user groups on target computers

.DESCRIPTION
Get a list of all available user groups on target computers

.PARAMETER Domain
One or more computers which to query for user groups

.PARAMETER CimSession
Specifies the CIM session to use

.EXAMPLE
PS> Get-UserGroup "ServerPC"

.EXAMPLE
PS> Get-UserGroup @(DESKTOP, LAPTOP)

.EXAMPLE
PS> Get-UserGroup -CimSession (New-CimSession)

.INPUTS
None. You cannot pipe objects to Get-UserGroup

.OUTPUTS
[PSCustomObject] User groups on target computers

.NOTES
None.
#>
function Get-UserGroup
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-UserGroup.md")]
	[OutputType("Ruleset.UserInfo.Group")]
	param (
		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string[]] $Domain = [System.Environment]::MachineName,

		[Parameter(ParameterSetName = "CimSession")]
		[CimSession] $CimSession
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	[hashtable] $CimParams = @{
		Namespace = "root\cimv2"
	}

	if ($PSCmdlet.ParameterSetName -eq "CimSession")
	{
		$Domain = $CimSession.ComputerName
		$CimParams.CimSession = $CimSession
	}

	foreach ($Computer in $Domain)
	{
		$MachineName = Format-ComputerName $Computer
		if ($PSCmdlet.ParameterSetName -eq "Domain")
		{
			$CimParams.ComputerName = $MachineName
		}

		if (($PSCmdlet.ParameterSetName -eq "Domain") -and ($MachineName -eq [System.Environment]::MachineName))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

			# Querying local machine
			$LocalGroups = Get-LocalGroup

			if ([string]::IsNullOrEmpty($LocalGroups))
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] There are no user groups on computer '$MachineName'"
			}

			foreach ($Group in $LocalGroups)
			{
				[PSCustomObject]@{
					Domain = $MachineName
					Group = $Group.Name
					Principal = Join-Path -Path $MachineName -ChildPath $Group.Name
					SID = $Group.SID
					LocalAccount = $Group.PrincipalSource -eq "Local"
					PSTypeName = "Ruleset.UserInfo.Group"
				}
			}
		}
		# Core: -TimeoutSeconds -IPv4
		elseif (Test-Computer $MachineName)
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting CIM server on $MachineName"

			$RemoteGroups = Get-CimInstance @CimParams -Class Win32_Group |
			Where-Object -Property LocalAccount -EQ "True"

			if ([string]::IsNullOrEmpty($RemoteGroups))
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] There are no user groups on computer '$MachineName'"
			}

			foreach ($Group in $RemoteGroups)
			{
				[PSCustomObject]@{
					Domain = $Group.Domain
					Group = $Group.Name
					Principal = $Group.Caption
					SID = $Group.SID
					LocalAccount = $Group.LocalAccount -eq "True"
					PSTypeName = "Ruleset.UserInfo.Group"
				}
			}
		}
	} # foreach ($MachineName in $Domain)
}
