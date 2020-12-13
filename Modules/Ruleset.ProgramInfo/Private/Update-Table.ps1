
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Fill data table with principal and program location

.DESCRIPTION
Module scope installation table is updated
Search system for programs with input search string, and add new program installation directory
to the table, as well as other information needed to make a firewall rule

.PARAMETER SearchString
Search string which corresponds to the output of "Get programs" functions

.PARAMETER UserProfile
true if user profile is to be searched too, system locations only otherwise

.PARAMETER Executable
Optionally specify executable name which will be search first.

.EXAMPLE
PS> Update-Table -Search "GoogleChrome"

.EXAMPLE
PS> Update-Table -Search "Microsoft Edge" -Executable "msedge.exe"

.EXAMPLE
PS> Update-Table -Search "Greenshot" -UserProfile

.INPUTS
None. You cannot pipe objects to Update-Table

.OUTPUTS
None. Update-Table does not generate any output

.NOTES
TODO: For programs in user profile rules should update LocalUser parameter accordingly,
currently it looks like we assign entry user group for program that applies to user only
TODO: Using "Executable" parameter should be possible without the use of "Search" parameter
TODO: Consider optional parameter for search by regex, wildcard, case sensitive or positional search
#>
function Update-Table
{
	[CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = "None")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("Search")]
		[AllowEmptyString()]
		[string] $SearchString,

		[Parameter()]
		[switch] $UserProfile,

		[Parameter()]
		[string] $Executable
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	if ($PSCmdlet.ShouldProcess("InstallTable", "Insert data into table"))
	{
		# To reduce typing and make code clear
		$UserGroups = Get-UserGroup -Computer $PolicyStore

		if (![string]::IsNullOrEmpty($Executable))
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching executable names for: $Executable"

			# TODO: executable paths search is too weak, need to handle more properties here
			$InstallLocation = $ExecutablePaths |
			Where-Object -Property Name -EQ $Executable |
			Select-Object -ExpandProperty InstallLocation

			if ($InstallLocation)
			{
				# Create a row
				$Row = $InstallTable.NewRow()

				# TODO: Learn username from installation path, probably a function for this
				$Principal = $UserGroups | Where-Object -Property Group -EQ "Users"

				# Enter data into row
				$Row.ID = ++$RowIndex
				$Row.SID = $Principal.SID
				$Row.Group = $Principal.Group
				$Row.Computer = $Principal.Computer
				$Row.InstallLocation = $InstallLocation

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Caption) with $InstallLocation"

				# Add row to the table
				$InstallTable.Rows.Add($Row)

				# TODO: If the path is known there is no need to continue?
				return
			}
		}
		elseif ([string]::IsNullOrEmpty($SearchString))
		{
			# Function was called to search by executables only
			return
		}

		# TODO: try to search also for path in addition to program name
		# TODO: SearchString may pick up irrelevant paths (ie. unreal engine), or even miss
		# Search system wide installed programs
		if ($SystemPrograms -and $SystemPrograms.Name -like "*$SearchString*")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching system programs for $SearchString"

			# TODO: need better mechanism for multiple matches
			$TargetPrograms = $SystemPrograms | Where-Object -Property Name -Like "*$SearchString*"
			$Principal = $UserGroups | Where-Object -Property Group -EQ "Users"

			foreach ($Program in $TargetPrograms)
			{
				# Create a row
				$Row = $InstallTable.NewRow()

				$InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

				# Enter data into row
				$Row.ID = ++$RowIndex
				$Row.SID = $Principal.SID
				$Row.Group = $Principal.Group
				$Row.Computer = $Principal.Computer
				$Row.InstallLocation = $InstallLocation

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Caption) with $InstallLocation"

				# Add row to the table
				$InstallTable.Rows.Add($Row)
			}
		}
		# Program not found on system, attempt alternative search
		elseif ($AllUserPrograms -and $AllUserPrograms.Name -like "*$SearchString*")
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching program install properties for $SearchString"
			$TargetPrograms = $AllUserPrograms | Where-Object -Property Name -Like "*$SearchString*"

			foreach ($Program in $TargetPrograms)
			{
				# Create a row
				$Row = $InstallTable.NewRow()

				# Let see who owns the sub key which is the SID
				$KeyOwner = ConvertFrom-SID $Program.SIDKey
				if ($KeyOwner -eq "Users")
				{
					$Principal = $UserGroups | Where-Object -Property Group -EQ "Users"
				}
				else
				{
					# TODO: we need more registry samples to determine what is right, Administrators seems logical
					$Principal = $UserGroups | Where-Object -Property Group -EQ "Administrators"
				}

				$InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

				# Enter data into row
				$Row.ID = ++$RowIndex
				$Row.SID = $Principal.SID
				$Row.Group = $Principal.Group
				$Row.Computer = $Principal.Computer
				$Row.InstallLocation = $InstallLocation

				Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Caption) with $InstallLocation"

				# Add row to the table
				$InstallTable.Rows.Add($Row)
			}
		}

		# Search user profiles
		# NOTE: User profile should be searched even if there is an installation system wide
		if ($UserProfile)
		{
			$Principals = Get-GroupPrincipal "Users"

			foreach ($Principal in $Principals)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Searching $($Principal.Account) programs for $SearchString"

				# TODO: We handle OneDrive case here but there may be more such programs in the future
				# so this obviously means we need better approach to handle this
				if ($SearchString -eq "OneDrive")
				{
					# NOTE: For one drive registry drilling procedure is different
					$UserPrograms = Get-OneDrive $Principal.User
				}
				else
				{
					# NOTE: the story is different here, each user might have multiple matches for search string
					# letting one match to have same principal would be mistake.
					$UserPrograms = Get-UserSoftware $Principal.User | Where-Object -Property Name -Like "*$SearchString*"
				}

				if ($UserPrograms)
				{
					foreach ($Program in $UserPrograms)
					{
						# NOTE: Avoid spamming
						# Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing program: $Program"

						$InstallLocation = $Program | Select-Object -ExpandProperty InstallLocation

						# Create a row
						$Row = $InstallTable.NewRow()

						# Enter data into row
						$Row.ID = ++$RowIndex
						$Row.SID = $Principal.SID
						$Row.User = $Principal.User
						# TODO: we should add group entry for users
						# $Row.Group = $Principal.Group
						$Row.Account = $Principal.Account
						$Row.Computer = $Principal.Computer
						$Row.InstallLocation = $InstallLocation

						Write-Debug -Message "[$($MyInvocation.InvocationName)] Updating table for $($Principal.Account) with $InstallLocation"

						# Add the row to the table
						$InstallTable.Rows.Add($Row)
					}
				}
			}
		}
	}
}
