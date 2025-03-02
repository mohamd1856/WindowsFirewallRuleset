
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
Get store app SID

.DESCRIPTION
Get SID for single store app if the app exists

.PARAMETER PackageFamilyName
"PackageFamilyName" string

.EXAMPLE
PS> Get-AppSID "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"

.INPUTS
[string] "PackageFamilyName" string

.OUTPUTS
[string] store app SID (security identifier)

.NOTES
Big thanks to ljani for this awesome solution, see issue from "related links" section

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/issues/6
#>
function Get-AppSID
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md")]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("FamilyName")]
		[string[]] $PackageFamilyName
	)

	begin
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

		$Sha256 = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")
	}
	process
	{
		foreach ($NameEntry in $PackageFamilyName)
		{
			$Hash = $Sha256.ComputeHash([System.Text.Encoding]::Unicode.GetBytes($NameEntry.ToLowerInvariant()))

			$SID = "S-1-15-2"
			for ($Length = 0; $Length -lt 28; $Length += 4)
			{
				$SID += "-" + [System.BitConverter]::ToUInt32($Hash, $Length)
			}

			Write-Output $SID
		}
	}
}
