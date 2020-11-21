
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Initialize unit test

.DESCRIPTION
Enter-Test initializes unit test, ie. to enable logging
This function must be called before first test case in single unit test

.PARAMETER Private
If specified temporarily exports private module functions into global scope

.EXAMPLE
PS> Enter-Test "Get-Something.ps1"

.INPUTS
None. You cannot pipe objects to Enter-Test

.OUTPUTS
None. Enter-Test does not generate any output

.NOTES
None.
#>
function Enter-Test
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Enter-Test.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[switch] $Private
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# Let Exit-Test know file name
	# NOTE: Global scope because this module could be removed before calling Exit-Test
	# NOTE: This will fail if Exit-Test was not called, restart PowerShell in that case
	Set-Variable -Name UnitTest -Scope Global -Option ReadOnly -Value ((Get-PSCallStack)[1].Command -replace ".{4}$")

	Write-Output ""
	Write-Information -Tags "Test" -MessageData "INFO: Entering unit test '$UnitTest'"

	if ($PSCmdlet.ShouldProcess("Enter unit test", $UnitTest))
	{
		New-Module -Name Dynamic.UnitTest -ScriptBlock {
			if ($Private)
			{
				# Temporarily export private functions to global scope
				$PrivateScript = Get-ChildItem -Path "$ProjectRoot\Modules" -Filter "Private" -Recurse -Depth 1 |
				ForEach-Object { Get-ChildItem -Path $_.FullName -Recurse -Filter *.ps1 }
				foreach ($Script in $PrivateScript) { . $Script.FullName }
			}

			# TODO: temporarily disabled
			if ($false)
			{
				# Disable logging errors, warnings and info messages for tests
				New-Variable -Name TestLogging -Option ReadOnly -Value @{
					ErrorLogging = $ErrorLogging
					WarningLogging = $WarningLogging
					InformationLogging = $InformationLogging
				}

				Set-Variable -Name ErrorLogging -Scope Global -Value $false
				Set-Variable -Name WarningLogging -Scope Global -Value $false
				Set-Variable -Name InformationLogging -Scope Global -Value $false

				Export-ModuleMember -Variable TestLogging
			}
		} | Import-Module -Scope Global

		Write-Debug -Message "[Enter-Test] ErrorLogging changed to: $ErrorLogging"
		Write-Debug -Message "[Enter-Test] WarningLogging changed to: $WarningLogging"
		Write-Debug -Message "[Enter-Test] InformationLogging changed to: $InformationLogging"
	}
}
