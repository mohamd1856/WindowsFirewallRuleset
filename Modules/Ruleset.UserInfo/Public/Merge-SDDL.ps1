
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
Merge 2 SDDL strings into one

.DESCRIPTION
This function helps to merge 2 SDDL strings into one
Referenced SDDL is expanded with new one

.PARAMETER SDDL
SDDL into which to merge new SDDL

.PARAMETER From
Reference SDDL string which to merge into original SDDL

.PARAMETER Unique
If specified, only SDDL's with unique SID are merged

.EXAMPLE
PS> $SDDL = "D:(A;;CC;;;S-1-5-32-545)(A;;CC;;;S-1-5-32-544)"
PS> $RefSDDL = "D:(A;;CC;;;S-1-5-32-333)(A;;CC;;;S-1-5-32-222)"
PS> Merge-SDDL ([ref] $SDDL) -From $RefSDDL

.INPUTS
None. You cannot pipe objects to Merge-SDDL

.OUTPUTS
None. Merge-SDDL does not generate any output

.NOTES
TODO: Validate input using regex
TODO: Process an array of SDDL's or Join-SDDL function to join multiple SDDL's
TODO: Pipeline input and -From parameter should accept an array.
#>
function Merge-SDDL
{
	[CmdletBinding(PositionalBinding = $false,
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.UserInfo/Help/en-US/Merge-SDDL.md")]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ref] $SDDL,

		[Parameter(Mandatory = $true)]
		[string] $From,

		[Parameter()]
		[switch] $Unique
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$MergedSDDL = $SDDL.Value + $From.Substring(2)

	if ($Unique)
	{
		$UniqueMerge = "D:"

		# Cache unique SID's
		$Cache = @()

		$SddlSplit = $MergedSDDL.Substring(2).Split("(", [System.StringSplitOptions]::RemoveEmptyEntries).TrimEnd(")")

		foreach ($SddlEntry in $SddlSplit)
		{
			$RegMatch = [regex]::Match($SddlEntry, "(?<SID>S-1-(\d+-)*\d+$)")

			if ($RegMatch.Success)
			{
				$SID = $RegMatch.Groups["SID"].Value

				if ($SID -notin $Cache)
				{
					# Cache SID so that SDDL entry isn't re-added
					$Cache += $SID

					# Merge SDDL if not cached
					$UniqueMerge += "($SddlEntry)"
				}
			}
			else
			{
				Write-Error -Category ParserError -TargetObject $RegMatch `
					-Message "Unable to parse SID from SDDL entry '$SddlEntry'"
				continue
			}
		}

		$SDDL.Value = $UniqueMerge
		return
	}

	$SDDL.Value = $MergedSDDL
}
