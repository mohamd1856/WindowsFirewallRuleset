
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2022 metablaster zebal@protonmail.ch

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
Get principals of specified groups on target computers

.DESCRIPTION
Get computer accounts for one or more user groups on local computer or one or more remote computers.

.PARAMETER Group
User group on local or remote computer

.PARAMETER Domain
One or more computers which to query for group users

.PARAMETER CimSession
Specifies the CIM session to use

.PARAMETER Include
Specifies a username as a wildcard pattern that this function includes in the operation.

.PARAMETER Exclude
Specifies a username as a wildcard pattern that this function excludes from operation.

.PARAMETER Disabled
If specified, result is disabled accounts instead

.EXAMPLE
PS> Get-GroupPrincipal "Users", "Administrators"

.EXAMPLE
PS> Get-GroupPrincipal "Users" -Domain @(DESKTOP, LAPTOP)

.EXAMPLE
PS> Get-GroupPrincipal "Users", "Administrators" -CimSession (New-CimSession)

.INPUTS
[string[]] User groups

.OUTPUTS
[PSCustomObject] Enabled user accounts in specified groups

.NOTES
TODO: should we handle NT AUTHORITY, BUILTIN and similar?
See also (according to docs but doesn't work): Get-LocalUser -Name "MicrosoftAccount\username@outlook.com"
#>
function Get-GroupPrincipal
{
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = "Domain",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Get-GroupPrincipal.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[Alias("UserGroup")]
		[string[]] $Group,

		[Parameter(ParameterSetName = "Domain")]
		[Alias("ComputerName", "CN")]
		[string[]] $Domain = [System.Environment]::MachineName,

		[Parameter(Mandatory = $true, ParameterSetName = "CimSession")]
		[CimSession] $CimSession,

		[Parameter()]
		[SupportsWildcards()]
		[string] $Include = "*",

		[Parameter()]
		[SupportsWildcards()]
		[string] $Exclude,

		[Parameter()]
		[switch] $Disabled
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		# Include/Exclude filter
		[scriptblock] $SkipUser = {
			param ([string] $User)

			if ($User -notlike $Include)
			{
				return $true
			}
			elseif (![string]::IsNullOrEmpty($Exclude) -and ($User -like $Exclude))
			{
				return $true
			}

			return $false
		}

		[hashtable] $CimParams = @{
			Namespace = "root\cimv2"
		}

		if ($PSCmdlet.ParameterSetName -eq "CimSession")
		{
			$Domain = $CimSession.ComputerName
			$CimParams.CimSession = $CimSession
		}
	}
	process
	{
		foreach ($Computer in $Domain)
		{
			# NOTE: Because $MachineName may be set to "localhost"
			$MachineName = Format-ComputerName $Computer
			if ($PSCmdlet.ParameterSetName -eq "Domain")
			{
				$CimParams.ComputerName = $MachineName
			}

			if (($PSCmdlet.ParameterSetName -eq "Domain") -and ($MachineName -eq [System.Environment]::MachineName))
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Querying localhost"

				foreach ($UserGroup in $Group)
				{
					Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing group: '$UserGroup'"

					# Querying local machine
					# TODO: The Microsoft.PowerShell.LocalAccounts module is not available in 32-bit PowerShell on a 64-bit system.
					$GroupUsers = Get-LocalGroupMember -Group $UserGroup | Where-Object {
						$_.ObjectClass -eq "User" -and
						($_.PrincipalSource -eq "Local" -or $_.PrincipalSource -eq "MicrosoftAccount")
					}

					if ([string]::IsNullOrEmpty($GroupUsers))
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] User group '$UserGroup' is empty or does not exist on computer '$MachineName'"
						continue
					}

					# Get either enabled or disabled users, these include SID but also non group users
					$EnabledAccounts = Get-LocalUser | Where-Object -Property Enabled -NE $Disabled

					if ([string]::IsNullOrEmpty($EnabledAccounts))
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] User group '$UserGroup' does not have any enabled accounts on computer '$MachineName'"
						continue
					}

					foreach ($Account in $EnabledAccounts)
					{
						if (& $SkipUser $Account.Name)
						{
							continue
						}

						$AccountName = [array]::Find([string[]] $GroupUsers.Name, [System.Predicate[string]] {
								Write-Debug -Message "[Get-GroupPrincipal] Comparing $($args[0]) with $MachineName\$($Account.Name)"
								$args[0] -eq "$MachineName\$($Account.Name)"
							})

						if ($AccountName)
						{
							Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $($Account.Name)"

							[PSCustomObject]@{
								Domain = $MachineName
								User = $Account.Name
								Group = $UserGroup
								Principal = $AccountName
								# NOTE: $Account.SID returns "AccountDomainSid" portion and the full SID of an account
								SID = $Account.SID.Value
								LocalAccount = $Account.PrincipalSource -eq "Local"
								PSTypeName = "Ruleset.UserInfo.Principal"
							}
						}
					}
				} # foreach ($UserGroup in $Group)
			}
			# Core: -TimeoutSeconds -IPv4
			elseif (Test-Computer $MachineName)
			{
				foreach ($UserGroup in $Group)
				{
					# Get all users that belong to requested group,
					# this includes non local principal source and non "user" users
					# it is also missing SID
					$GroupUsers = Get-CimInstance @CimParams -Class Win32_GroupUser -Property GroupComponent, PartComponent |
					Where-Object { $_.GroupComponent.Name -eq $UserGroup } |
					Select-Object -ExpandProperty PartComponent

					if ([string]::IsNullOrEmpty($GroupUsers))
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] User group '$UserGroup' is empty or does not exist on computer '$MachineName'"
						continue
					}

					# Get either enabled or disabled users, these include SID but also non group users
					$EnabledAccounts = Get-CimInstance @CimParams -Class Win32_UserAccount `
						-Property LocalAccount, Disabled, Caption, Domain, Name -Filter "LocalAccount = True" |
					Where-Object -Property Disabled -EQ $Disabled  #| Select-Object -Property Name, Caption, SID, Domain

					if ([string]::IsNullOrEmpty($EnabledAccounts))
					{
						Write-Warning -Message "[$($MyInvocation.InvocationName)] User group '$UserGroup' does not have any enabled accounts on computer '$MachineName'"
						continue
					}

					# Finally compare these 2 results and assemble group users which are active, also includes SID
					foreach ($Account in $EnabledAccounts)
					{
						if (& $SkipUser $Account.Name)
						{
							continue
						}

						$UserName = [array]::Find([string[]] $GroupUsers.Name, [System.Predicate[string]] {
								Write-Debug -Message "[Get-GroupPrincipal] Comparing $($Account.Caption) with $($Account.Domain)\$($args[0])"
								# NOTE: Account.Domain or $MachineName is same thing
								$Account.Caption -eq "$($Account.Domain)\$($args[0])"
							})

						if ($UserName)
						{
							Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing account: $Account"

							# NOTE: $Account.SID may be empty
							$Principal = Get-PrincipalSID -User $Account.Name -CimSession $CimSession

							[PSCustomObject]@{
								Domain = $Account.Domain
								User = $Account.Name
								Group = $UserGroup
								Principal = $Account.Caption
								SID = $Principal.SID
								# TODO: Figure out if it's MS account using CIM
								LocalAccount = $Account.LocalAccount -eq "True"
								PSTypeName = "Ruleset.UserInfo"
							}
						}
						else
						{
							Write-Debug -Message "[$($MyInvocation.InvocationName)] Ignoring account: $Account"
						}
					}
				}
			}
		} # foreach ($MachineName in $Domain)
	} # process
}
