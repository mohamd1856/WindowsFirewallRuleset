
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

#region Initialization
param (
	[Parameter()]
	[switch] $ListPreference
)

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1 -InModule -ListPreference:$ListPreference

if ($ListPreference)
{
	# NOTE: Preferences defined in caller scope are not inherited, only those defined in
	# Config\ProjectSettings.ps1 are pulled into module scope
	Write-Debug -Message "[$ThisModule] InformationPreference in module: $InformationPreference" -Debug
	Show-Preference # -All
	Remove-Module -Name Dynamic.Preference
}
#endregion

#
# Script imports
#

Write-Debug -Message "[$ThisModule] Dotsourcing scripts"

$ScriptsToProcess = @(
)

foreach ($Script in $ScriptsToProcess)
{
	try
	{
		. "$PSScriptRoot\Scripts\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Scripts\$Script.ps1' $($_.Exception.Message)"
	}
}

$PrivateScripts = @(
)

foreach ($Script in $PrivateScripts)
{
	try
	{
		. "$PSScriptRoot\Private\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Private\$Script.ps1' $($_.Exception.Message)"
	}
}

$PublicScripts = @(
	"Debug-Experiment"
)

foreach ($Script in $PublicScripts)
{
	try
	{
		. "$PSScriptRoot\Public\$Script.ps1"
	}
	catch
	{
		Write-Error -Category ReadError -TargetObject $Script `
			-Message "Failed to import script '$ThisModule\Public\$Script.ps1' $($_.Exception.Message)"
	}
}

Export-ModuleMember -Function $PublicScripts

#
# Module variables
#

Write-Debug -Message "[$ThisModule] Initializing module variables"

# Template variable
New-Variable -Name ModuleVariable -Scope Script -Value "Module variable"

#
# Module aliases
#

Write-Debug -Message "[$ThisModule] Creating aliases"
New-Alias -Name testvar -Value ModuleVariable
Export-ModuleMember -Alias testvar

#
# Module cleanup
#

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	Write-Debug -Message "[$ThisModule] Performing module cleanup"

	# Do module cleanup here is necessary...
}
