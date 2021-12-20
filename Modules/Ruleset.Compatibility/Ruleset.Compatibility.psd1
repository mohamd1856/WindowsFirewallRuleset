
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch
Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved

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

#
# Module manifest for module "Ruleset.Compatibility"
#
# Generated by: metablaster
#
# Generated on: 14.11.2020.
#

@{
	# Script module or binary module file associated with this manifest, (alias: ModuleToProcess)
	# Previous versions of PowerShell called this element the ModuleToProcess.
	# NOTE: To create a manifest module this must be empty,
	# the name of a script module (.psm1) creates a script module,
	# the name of a binary module (.exe or .dll) creates a binary module.
	RootModule = "Ruleset.Compatibility.psm1"

	# Version number of this module.
	ModuleVersion = "0.11.0"

	# Supported PSEditions
	CompatiblePSEditions = @("Core")

	# ID used to uniquely identify this module
	GUID = "eb203a5b-d397-4909-9fe9-00b0f083f36a"

	# Author of this module
	Author = "PowerShell"

	# Company or vendor of this module
	CompanyName = "Microsoft Corporation"

	# Copyright statement for this module
	Copyright = "Copyright (C) 2018, 2019 Microsoft Corporation. All rights reserved"

	# Description of the functionality provided by this module
	Description = @'
This module provides compatibility utilities that allow PowerShell Core sessions to
invoke commands that are only available in Windows PowerShell. These utilities help you
to discover available modules, import those modules through proxies and then use the module
commands much as if they were native to PowerShell Core.
'@

	# Minimum version of the PowerShell engine required by this module
	# Valid values are: 1.0 / 2.0 / 3.0 / 4.0 / 5.0 / 5.1 / 6.0 / 6.1 / 6.2 / 7.0 / 7.1
	PowerShellVersion = "6.0"

	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = "ConsoleHost"

	# Minimum version of the PowerShell host required by this module
	# PowerShellHostVersion = ""

	# Minimum version of Microsoft .NET Framework required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	# Valid values are: 1.0 / 1.1 / 2.0 / 3.0 / 3.5 / 4.0 / 4.5
	# DotNetFrameworkVersion = "4.5"

	# Minimum version of the common language runtime (CLR) required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	# Valid values are: 1.0 / 1.1 / 2.0 / 4.0
	# CLRVersion = "4.0"

	# Processor architecture (None, X86, Amd64) required by this module.
	# Valid values are: x86 / AMD64 / Arm / IA64 / MSIL / None (unknown or unspecified).
	ProcessorArchitecture = "None"

	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess = @()

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule.
	# Loading (.ps1) files here is equivalent to dot sourcing the script in your root module.
	# NestedModules = @()

	# Functions to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no functions to export.
	# NOTE: When the value of any *ToExport key is an empty array,
	# no objects of that type are exported, regardless of the value in the Export-ModuleMember
	FunctionsToExport = @(
		"Add-WindowsPSModulePath"
		"Add-WinFunction"
		"Compare-WinModule"
		"Copy-WinModule"
		"Get-WinModule"
		"Import-WinModule"
		"Initialize-WinSession"
		"Invoke-WinCommand"
	)

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport = @()

	# Variables to export from this module.
	# Wildcard characters are permitted, by default, all variables ("*") are exported.
	VariablesToExport = @()

	# Aliases to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport = @("Add-WinPSModulePath")

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module.
	# These modules are not automatically processed.
	# ModuleList = @()

	# List of all files packaged with this module.
	# As with ModuleList, FileList is an inventory list.
	FileList = @(
		"en-US\about_Ruleset.Compatibility.help.txt"
		"en-US\Ruleset.Compatibility-help.xml"
		"Help\en-US\about_Ruleset.Compatibility.md"
		"Help\en-US\Add-WindowsPSModulePath.md"
		"Help\en-US\Add-WinFunction.md"
		"Help\en-US\Compare-WinModule.md"
		"Help\en-US\Copy-WinModule.md"
		"Help\en-US\Get-WinModule.md"
		"Help\en-US\Import-WinModule.md"
		"Help\en-US\Initialize-WinSession.md"
		"Help\en-US\Invoke-WinCommand.md"
		"Help\en-US\Ruleset.Compatibility.md"
		"Help\QuickStart.md"
		"Help\README.md"
		"Public\Add-WindowsPSModulePath.ps1"
		"Public\Add-WinFunction.ps1"
		"Public\Compare-WinModule.ps1"
		"Public\Copy-WinModule.ps1"
		"Public\Get-WinModule.ps1"
		"Public\Import-WinModule.ps1"
		"Public\Initialize-WinSession.ps1"
		"Public\Invoke-WinCommand.ps1"
		"Public\README.md"
		"Test\CompatibilitySession.Test.ps1"
		"Test\PSModulePath.Test.ps1"
		"LICENSE"
		"README.md"
		"Ruleset.Compatibility_eb203a5b-d397-4909-9fe9-00b0f083f36a_HelpInfo.xml"
		"Ruleset.Compatibility.psd1"
		"Ruleset.Compatibility.psm1"
	)

	# Specifies any private data that needs to be passed to the root module specified by the RootModule.
	# This contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		PSData = @{

			# Tags applied to this module.
			# These help with module discovery in online galleries.
			Tags = @(
				"Compatibility"
				"WindowsPowerShell"
				"Core"
			)

			# A URL to the license for this module.
			LicenseUri = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Modules/Ruleset.Compatibility/LICENSE"

			# A URL to the main website for this project.
			ProjectUri = "https://github.com/metablaster/WindowsFirewallRuleset"

			# A URL to an icon representing this module.
			# The specified icon is displayed on the gallery webpage for the module
			IconUri = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Readme/Screenshots/bluewall.png"

			# ReleaseNotes of this module
			ReleaseNotes = @'
This module provides a set of commands that allow you to use
Windows PowerShell modules from PowerShell Core (PowerShell 6).
The following commands are included:
    Initialize-WinSession
    Add-WinFunction
    Invoke-WinCommand
    Get-WinModule
    Import-WinModule
    Compare-WinModule
    Copy-WinModule
See the help for the individual commands for examples on how
to use this functionality.

Additionally, the command `Add-WindowsPSModulePath` will update
your $ENV:PSModulePath to include Windows PowerShell module directories
within PowerShell Core 6.

NOTE: This release is only intended to be used with PowerShell Core 6
running on Microsoft Windows. Linux and MacOS are not supported at this
time.
'@

			# A PreRelease string that identifies the module as a prerelease version in online galleries.
			# Prerelease = ""

			# Flag to indicate whether the module requires explicit user acceptance for
			# install, update, or save.
			RequireLicenseAcceptance = $true

			# A list of external modules that this module is dependent upon.
			# ExternalModuleDependencies = @()
		} # End of PSData hashtable
	} # End of PrivateData hashtable

	# Updatable Help uses the HelpInfoURI key in the module manifest to find the Help information
	# (HelpInfo XML) file that contains the location of the updated help files for the module.
	# HelpInfoURI = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Modules/Ruleset.Compatibility/Ruleset.Compatibility_eb203a5b-d397-4909-9fe9-00b0f083f36a_HelpInfo.xml"

	# Default prefix for commands exported from this module.
	# Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ""
}
