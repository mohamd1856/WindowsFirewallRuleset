
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
Unit test for Get-FileEncoding

.DESCRIPTION
Test correctness of Get-FileEncoding function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-FileEncoding.ps1

.INPUTS
None. You cannot pipe objects to Get-FileEncoding.ps1

.OUTPUTS
None. Get-FileEncoding.ps1 does not generate any output

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

Enter-Test "Get-FileEncoding"

# Start-Test "windows-1251"
# Get-FileEncoding $PSScriptRoot\Encoding\utf8.txt -Encoding "windows-1251"

# Start-Test "932"
# Get-FileEncoding $PSScriptRoot\Encoding\utf8.txt -Encoding 932

$TestFiles = Get-ChildItem -Path "$PSScriptRoot\Encoding\*" -Filter "*.test"
$TestFiles += Get-ChildItem -Path "$PSScriptRoot\Encoding\*" -Filter "*.ansi"
$TestFiles += "$env:SystemRoot\regedit.exe"

foreach ($File in $TestFiles)
{
	Start-Test "$File"
	$Result = Get-FileEncoding $File
	$Result
}

Test-Output $Result -Command Get-FileEncoding

Update-Log
Exit-Test
