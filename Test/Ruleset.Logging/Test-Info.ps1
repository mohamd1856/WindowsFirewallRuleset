
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
Unit test for info logging

.DESCRIPTION
Test correctness of info logging

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-Info.ps1

.INPUTS
None. You cannot pipe objects to Test-Info.ps1

.OUTPUTS
None. Test-Info.ps1 does not generate any output

.NOTES
None.
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

<#
.SYNOPSIS
	Info logging with advanced function
#>
function Test-Info
{
	[CmdletBinding()]
	param ()

	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: info 1"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: info 2"
}

<#
.SYNOPSIS
	Info logging on pipeline
#>
function Test-Pipeline
{
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$Param
	)

	process
	{
		# Use param to avoid PSScriptAnalyzer warning
		Write-Debug -Message $Param -Debug:$false

		Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: End of pipe 1"
		Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: End of pipe 2"
	}
}

<#
.SYNOPSIS
	Info logging with nested function
#>
function Test-Nested
{
	[CmdletBinding()]
	param ()

	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: Nested 1"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: Nested 2"
}

<#
.SYNOPSIS
	Info logging with nested function
#>
function Test-Parent
{
	[CmdletBinding()]
	param ()

	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: Parent 1"
	Test-Nested
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: Parent 2"
}

<#
.SYNOPSIS
	Info logging with a combination of other streams
#>
function Test-Combo
{
	[CmdletBinding()]
	param ()

	Write-Error -Category PermissionDenied -Message "[$($MyInvocation.MyCommand.Name)] combo" -ErrorId 11
	Write-Warning -Message "[$($MyInvocation.InvocationName)] combo"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: combo"
}

<#
.SYNOPSIS
	Pipeline helper
#>
function Test-Empty
{
	[CmdletBinding()]
	param ()

	Write-Output "Data.."
}

Enter-Test

# NOTE: we test generating logs not what is shown in the console
# disabling this for "Invoke-AllTests"
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"

# Clear test logs
Get-ChildItem -Path "$LogsFolder\Test\*_$(Get-Date -Format "dd.MM.yy").log" | Remove-Item

Start-Test '$PSDefaultParameterValues in script'
$PSDefaultParameterValues

Start-Test "No info"
Get-ChildItem -Path $env:SystemDrive | Out-Null

Start-Test "Update-Log no info"
Update-Log

Start-Test "Test-Info"
Test-Info

Start-Test "Update-Log second time"
Update-Log

Start-Test "Test-Pipeline"
Test-Empty | Test-Pipeline

Start-Test "Test-Parent"
Test-Parent

Start-Test "Test-Combo"
Test-Combo

Start-Test "Create module"
New-Module -Name Dynamic.TestInfo -ScriptBlock {
	. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule

	# NOTE: Same thing as in parent scope, we test generating logs not what is shown in the console
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
	$InformationPreference = "SilentlyContinue"

	# TODO: Start-Test cant be used here, see todo in Ruleset.Test module
	if ($null -eq $PSDefaultParameterValues)
	{
		Write-Information -Tags "Test" -MessageData "[Dynamic.TestInfo] PSDefaultParameterValues is null" -InformationAction "Continue"
	}
	else
	{
		Write-Information -Tags "Test" -MessageData "[Dynamic.TestInfo] `$PSDefaultParameterValues is '$($PSDefaultParameterValues | Out-String)'" -InformationAction "Continue"
	}

	<#
	.SYNOPSIS
	Test default parameter values and information loging inside module function
	#>
	function Test-DynamicFunction
	{
		[CmdletBinding()]
		param ()

		if ($null -eq $PSDefaultParameterValues)
		{
			Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] PSDefaultParameterValues in is null" -InformationAction "Continue"
		}
		else
		{
			Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] `$PSDefaultParameterValues is '$($PSDefaultParameterValues | Out-String)'" -InformationAction "Continue"
		}

		Write-Information -Tags "Test" -MessageData "[$($MyInvocation.InvocationName)] INFO: info in module"
	}
} | Import-Module

New-Test "Test-DynamicFunction"
Test-DynamicFunction
Remove-Module -Name Dynamic.TestInfo

Start-Test "Update-Log last time"
Update-Log

Exit-Test
