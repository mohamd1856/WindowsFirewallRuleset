
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
Script experiment

.DESCRIPTION
Use New-Experiment.ps1 to write temporary tests

.PARAMETER Force
Implement this switch to override default behavior

.EXAMPLE
PS> .\New-Experiment.ps1

.INPUTS
None. You cannot pipe objects to New-Experiment.ps1

.OUTPUTS
None. New-Experiment.ps1 does not generate any output

.NOTES
None.
#>

[CmdletBinding()]
param (
	[Parameter()]
	[Alias("ComputerName", "CN", "PolicyStore")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

begin
{
	. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet -TargetHost $Domain
	Import-Module -Name $PSScriptRoot\Experiment.Module -Scope Global -Force:$Force

	$DebugPreference = "Continue"
	Write-Debug -Message "[$ThisScript] Run module function"
	Debug-Experiment
}

process
{
	Write-Debug -Message "[$ThisScript] INFO: Run script function"
}

end
{
}
