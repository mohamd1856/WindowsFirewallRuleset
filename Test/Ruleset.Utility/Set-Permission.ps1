
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
Unit test for Set-Permission

.DESCRIPTION
Test correctness of Set-Permission function

.PARAMETER FileSystem
Test setting file system permissions/ownership

.PARAMETER Registry
Test setting registry permissions/ownership

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Set-Permission.ps1 -FileSystem

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Set-Permission.ps1 -Registry -FileSystem

.INPUTS
None. You cannot pipe objects to for Set-Permission.ps1

.OUTPUTS
None. Set-Permission.ps1 does not generate any output

.NOTES
None.
#>

using namespace System.Security
#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $FileSystem,

	[Parameter()]
	[switch] $Registry,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Unsafe -Force:$Force)) { exit }
#endregion

Enter-Test "Set-Permission"

if ($FileSystem)
{
	# Set up test variables
	$Computer = [System.Environment]::MachineName
	$TestDrive = "$DefaultTestDrive\$ThisScript"
	$PSDefaultParameterValues.Add("Set-Permission:Force", $Force)
	$PSDefaultParameterValues.Add("Set-Permission:Confirm", $false)

	[AccessControl.FileSystemRights] $Access = "ReadAndExecute, ListDirectory, Traverse"

	while ($true)
	{
		# NOTE: temporary reset
		if (Test-Path -LiteralPath $TestDrive)
		{
			# Test ownership
			Start-Test "Take ownership"
			if (Set-Permission -Owner $TestAdmin -Domain $Computer -LiteralPath $TestDrive -Recurse)
			{
				# Reset existing tree for re-test
				Start-Test "Reset existing tree"
				if (Set-Permission -User $TestAdmin -Domain $Computer -LiteralPath $TestDrive -Reset -Grant $Access -Recurse)
				{
					Reset-TestDrive
					break
				}
			}

			return
		}
	}

	$TestFolders = @(
		"DenyRights"
		"Inheritance"
		"Protected"
		"Recurse"
	)
	$TestFiles = @(
		"NT Service.txt"
		"LocalService.txt"
		"Remote Management Users.txt"
		"Recurse.txt"
	)

	# Create root test folder
	if (!(Test-Path -PathType Container -Path $TestDrive))
	{
		Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory '$TestDrive'"
		New-Item -ItemType Container -Path $TestDrive | Out-Null
	}

	# Create subfolder files and directories
	$FileIndex = 0
	foreach ($Folder in $TestFolders)
	{
		if (!(Test-Path -PathType Container -Path $TestDrive\$Folder))
		{
			Write-Information -Tags "Test" -MessageData "INFO: Creating new test directory '$Folder'"
			New-Item -ItemType Container -Path $TestDrive\$Folder | Out-Null
			New-Item -ItemType Container -Path $TestDrive\$Folder\$Folder | Out-Null
			New-Item -ItemType File -Path $TestDrive\$Folder\$($TestFiles[$FileIndex]) | Out-Null
		}

		++$FileIndex
	}

	# Create test files
	foreach ($File in $TestFiles)
	{
		if (!(Test-Path -PathType Leaf -Path $TestDrive\$File))
		{
			Write-Information -Tags "Test" -MessageData "INFO: Creating new test file '$File'"
			New-Item -ItemType File -Path $TestDrive\$File | Out-Null
		}
	}

	# Test ownership
	Start-Test "ownership"
	Set-Permission -Owner $TestUser -Domain $Computer -LiteralPath $TestDrive

	# Test defaults
	Start-Test "NT SERVICE\LanmanServer permission on file"
	Set-Permission -User "LanmanServer" -Domain "NT SERVICE" -LiteralPath "$TestDrive\$($TestFiles[0])" -Rights $Access

	Start-Test "Local Service permission on file"
	Set-Permission -User "Local Service" -LiteralPath "$TestDrive\$($TestFiles[1])" -Grant $Access

	Start-Test "Group permission on file"
	Set-Permission -User "Remote Management Users" -LiteralPath "$TestDrive\$($TestFiles[2])" -Grant $Access

	# Test parameters
	Start-Test "NT SERVICE\LanmanServer permission on folder"
	Set-Permission -User "LanmanServer" -Domain "NT SERVICE" -LiteralPath "$TestDrive\$($TestFolders[0])" `
		-Type "Deny" -Rights "TakeOwnership, Delete, Modify"

	Start-Test "Local Service permission on folder"
	Set-Permission -User "Local Service" -LiteralPath "$TestDrive\$($TestFolders[1])" `
		-Type "Allow" -Inheritance "ObjectInherit" -Propagation "NoPropagateInherit" -Grant $Access

	Start-Test "Group permission on folder"
	$Result = Set-Permission -User "Remote Management Users" -LiteralPath "$TestDrive\$($TestFolders[2])" -Grant $Access `
		-Protected

	$Result

	# Test output type
	Test-Output $Result -Command Set-Permission

	# Test reset/recurse
	Start-Test "Reset permissions inheritance to explicit"
	Set-Permission -LiteralPath "$TestDrive\Protected\Remote Management Users.txt" -Reset -Protected -PreserveInheritance

	Start-Test "Reset permissions recurse"
	Set-Permission -User "Administrators" -Grant "FullControl" -LiteralPath $TestDrive -Reset -Recurse

	Start-Test "Recursive ownership on folder"
	Set-Permission -Owner "Replicator" -LiteralPath $TestDrive -Recurse

	Start-Test "Recursively reset"
	Set-Permission -LiteralPath $TestDrive -Reset -Recurse

	Start-Test "Recursively clear all rules or folder"
	Set-Permission -LiteralPath $TestDrive -Reset -Recurse -Protected
}
elseif ($Registry)
{
	if ($PSCmdlet.ShouldContinue("Modify registry ownership or permissions", "Accept potentially dangerous unit test"))
	{
		# NOTE: This test may fail until Set-Privilege script is considered into Set-Permission function
		# Ownership + Full control
		$TestKey = "TestKey"

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening registry hive"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser
		$RegistryView = [Microsoft.Win32.RegistryView]::Registry64

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry"
			$RootKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView)
		}
		catch
		{
			Write-Error -ErrorRecord $_
			Update-Log
			Exit-Test
			return
		}

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening sub key: HKCU\:$TestKey"
			[Microsoft.Win32.RegistryKey] $SubKey = $RootKey.OpenSubkey($TestKey, $RegistryPermission, $RegistryRights)
		}
		catch
		{
			$RootKey.Dispose()
			Write-Error -ErrorRecord $_
			Update-Log
			Exit-Test
			return
		}

		# TODO: Return value is 'HKEY_CURRENT_USER\TestKey'
		$KeyLocation = $SubKey.Name # "HKCU:\TestKey" #

		# Take ownership and set full control
		# NOTE: setting other owner (except current user) will not work for HKCU
		Set-Permission -User "TrustedInstaller" -Domain "NT SERVICE" -LiteralPath $KeyLocation -Reset -RegistryRight "ReadKey"
		Set-Permission -Owner "TrustedInstaller" -Domain "NT SERVICE" -LiteralPath $KeyLocation

		Set-Permission -User $TestUser -LiteralPath $KeyLocation -Reset -RegistryRight "ReadKey"
		Set-Permission -Owner $TestUser -LiteralPath $KeyLocation

		$RootKey.Dispose()
	}
}

Update-Log
Exit-Test
