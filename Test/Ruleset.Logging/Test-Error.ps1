
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
Unit test for error logging

.DESCRIPTION
Test correctness of error logging

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Test-Error.ps1

.INPUTS
None. You cannot pipe objects to Test-Error.ps1

.OUTPUTS
None. Test-Error.ps1 does not generate any output

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
	Error logging with advanced function
#>
function Test-Error
{
	[CmdletBinding()]
	param ()

	Start-Test '$PSDefaultParameterValues in Test-Error'
	$PSDefaultParameterValues

	Write-Error -Category PermissionDenied -Message "[$($MyInvocation.InvocationName)] error 1" -ErrorId 1
	Write-Error -Category PermissionDenied -Message "[$($MyInvocation.InvocationName)] error 2" -ErrorId 2
}

<#
.SYNOPSIS
	Error logging on pipeline
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

		Write-Error -Category NotEnabled -Message "[$($MyInvocation.InvocationName)] End of pipe 1" -ErrorId 3
		Write-Error -Category NotEnabled -Message "[$($MyInvocation.InvocationName)] End of pipe 2" -ErrorId 4
	}
}

<#
.SYNOPSIS
	Error logging with nested function
#>
function Test-Nested
{
	[CmdletBinding()]
	param ()

	Start-Test '$PSDefaultParameterValues in Test-Nested'
	$PSDefaultParameterValues

	Write-Error -Category SyntaxError -Message "[$($MyInvocation.InvocationName)] Nested 1" -ErrorId 5
	Write-Error -Category SyntaxError -Message "[$($MyInvocation.InvocationName)] Nested 2" -ErrorId 6
}

<#
.SYNOPSIS
	Error logging with nested function
#>
function Test-Parent
{
	[CmdletBinding()]
	param ()

	Write-Error -Category MetadataError -Message "[$($MyInvocation.InvocationName)] Parent 1" -ErrorId 7
	Test-Nested
	Write-Error -Category MetadataError -Message "[$($MyInvocation.InvocationName)] Parent 2" -ErrorId 8
}

<#
.SYNOPSIS
	Error logging with a combination of other streams
#>
function Test-Combo
{
	[CmdletBinding()]
	param ()

	Write-Error -Category InvalidResult -Message "[$($MyInvocation.InvocationName)] combo" -ErrorId 9
	Write-Warning -Message "[$($MyInvocation.MyCommand.Name)] combo"
	Write-Information -Tags "Test" -MessageData "[$($MyInvocation.MyCommand.Name)] INFO: combo"
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

Start-Test "No errors"
Get-ChildItem -Path $env:SystemDrive | Out-Null

Start-Test "Update-Log no errors"
Update-Log

Start-Test "Generate errors"
Get-ChildItem -Path "$env:SystemDrive\CrazyFolder"

Start-Test "Update-Log second time"
Update-Log

Start-Test "Test-Error"
Test-Error

Start-Test "Test-Pipeline"
Test-Empty | Test-Pipeline

Start-Test "Test-Parent"
Test-Parent

Start-Test "Test-Combo"
Test-Combo

Start-Test "Create module"
New-Module -Name Dynamic.TestError -ScriptBlock {
	. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 -InModule

	# NOTE: Same thing as in parent scope, we test generating logs not what is shown in the console
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
	$InformationPreference = "SilentlyContinue"

	# TODO: Start-Test cant be used here, see todo in Ruleset.Test module
	if ($null -eq $PSDefaultParameterValues)
	{
		Write-Information -Tags "Test" -MessageData "[Dynamic.TestError] PSDefaultParameterValues is null" -InformationAction "Continue"
	}
	else
	{
		Write-Information -Tags "Test" -MessageData "[Dynamic.TestError] `$PSDefaultParameterValues is '$($PSDefaultParameterValues | Out-String)'" -InformationAction "Continue"
	}

	<#
	.SYNOPSIS
	Test default parameter values and error loging inside module function
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

		Write-Error -Category NotSpecified -Message "[$($MyInvocation.InvocationName)] error in module" -ErrorId 10
	}
} | Import-Module

New-Test "Test-DynamicFunction"
Test-DynamicFunction
Remove-Module -Name Dynamic.TestError

Start-Test "Update-Log last time"
Update-Log

Exit-Test
