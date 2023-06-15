
<#
NOTE: This file has been sublicensed by metablaster zebal@protonmail.ch
under a dual license of the MIT license AND the Apache license, see both licenses below
#>

<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

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
Apache License

Copyright (C) 2015 Dave Wyatt

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

#
# Module manifest for module "Ruleset.PolicyFileEditor"
#
# Generated by: metablaster
#
# Generated on: 27.11.2022.
#

@{
	# Script module or binary module file associated with this manifest, (alias: ModuleToProcess)
	# Previous versions of PowerShell called this element the ModuleToProcess.
	# NOTE: To create a manifest module this must be empty,
	# the name of a script module (.psm1) creates a script module,
	# the name of a binary module (.exe or .dll) creates a binary module.
	RootModule = "Ruleset.PolicyFileEditor.psm1"

	# Version number of this module.
	# NOTE: Last checked out official version was 3.0.1
	ModuleVersion = "0.15.1"

	# Supported PSEditions
	CompatiblePSEditions = @(
		"Core"
		"Desktop"
	)

	# ID used to uniquely identify this module
	# NOTE: guid of a original module was: 110a2398-3053-4ffc-89d1-1b6a38a2dc86
	GUID = "c321c0fc-a6d8-4251-8f71-c69d8a57ce8f"

	# Author of this module
	Author = "Dave Wyatt"

	# Company or vendor of this module
	# CompanyName = "Unknown"

	# Copyright statement for this module
	Copyright = "Copyright (C) 2015 Dave Wyatt"

	# Description of the functionality provided by this module
	Description = "Module for modifying Administrative Templates settings in local GPO registry.pol files"

	# Minimum version of the PowerShell engine required by this module
	# Valid values are: 1.0 / 2.0 / 3.0 / 4.0 / 5.0 / 5.1 / 6.0 / 6.1 / 6.2 / 7.0 / 7.1
	PowerShellVersion = "5.1"

	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = ""

	# Minimum version of the Windows PowerShell host required by this module
	# PowerShellHostVersion = ""

	# Minimum version of Microsoft .NET Framework required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	# Valid values are: 1.0 / 1.1 / 2.0 / 3.0 / 3.5 / 4.0 / 4.5
	DotNetFrameworkVersion = "4.5"

	# Minimum version of the common language runtime (CLR) required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	# Valid values are: 1.0 / 1.1 / 2.0 / 4.0
	CLRVersion = "4.0"

	# Processor architecture (None, X86, Amd64) required by this module.
	# Valid values are: x86 / AMD64 / Arm / IA64 / MSIL / None (unknown or unspecified).
	ProcessorArchitecture = "None"

	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @(
		"PolFileEditor.dll"
	)

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
		"Get-PolicyFileEntry"
		"Remove-PolicyFileEntry"
		"Set-PolicyFileEntry"
		"Update-GptIniVersion"
	)

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport = @()

	# Variables to export from this module.
	# Wildcard characters are permitted, by default, all variables ("*") are exported.
	VariablesToExport = @()

	# Aliases to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport = @()

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module.
	# These modules are not automatically processed.
	# ModuleList = @()

	# List of all files packaged with this module.
	# As with ModuleList, FileList is an inventory list.
	FileList = @(
		"en-US\about_Ruleset.PolicyFileEditor.Help.txt"
		"en-US\Ruleset.PolicyFileEditor-help.xml"
		"Help\en-US\about_Ruleset.PolicyFileEditor.md"
		"Help\en-US\Get-PolicyFileEntry.md"
		"Help\en-US\Remove-PolicyFileEntry.md"
		"Help\en-US\Ruleset.PolicyFileEditor.md"
		"Help\en-US\Set-PolicyFileEntry.md"
		"Help\en-US\Update-GptIniVersion.md"
		"Help\README.md"
		"Private\Assert-InvalidDataTypeCombinationErrorRecord.ps1"
		"Private\Assert-ValidDataAndType.ps1"
		"Private\Confirm-AdminTemplateCseGuidsArePresent.ps1"
		"Private\Convert-PolicyEntryToPsObject.ps1"
		"Private\Convert-PolicyEntryTypeToRegistryValueKind.ps1"
		"Private\Convert-UInt16PairToUInt32.ps1"
		"Private\Convert-UInt32ToUInt16Pair.ps1"
		"Private\Get-EntryData.ps1"
		"Private\Get-KeyValueName.ps1"
		"Private\Get-NewVersionNumber.ps1"
		"Private\Get-PolicyFilePath.ps1"
		"Private\Get-SidForAccount.ps1"
		"Private\New-GptIni.ps1"
		"Private\Open-PolicyFile.ps1"
		"Private\README.md"
		"Private\Save-PolicyFile.ps1"
		"Private\Test-DataIsEqual.ps1"
		"Public\Get-PolicyFileEntry.ps1"
		"Public\README.md"
		"Public\Remove-PolicyFileEntry.ps1"
		"Public\Set-PolicyFileEntry.ps1"
		"Public\Update-GptIniVersion.ps1"
		"Sources\PolicyFileEditor.cs"
		"Test\Ruleset.PolicyFileEditor.Tests.ps1"
		"LICENSE"
		"PolFileEditor.dll"
		"README.md"
		"Ruleset.PolicyFileEditor_c321c0fc-a6d8-4251-8f71-c69d8a57ce8f_HelpInfo.xml"
		"Ruleset.PolicyFileEditor.psd1"
		"Ruleset.PolicyFileEditor.psm1"
	)

	# Specifies any private data that needs to be passed to the root module specified by the RootModule.
	# This contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		PSData = @{

			# Tags applied to this module.
			# These help with module discovery in online galleries.
			Tags = @(
				"GPO"
			)

			# A URL to the license for this module.
			LicenseUri = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Modules/Ruleset.PolicyFileEditor/LICENSE"

			# A URL to the main website for this project.
			ProjectUri = "https://github.com/metablaster/WindowsFirewallRuleset"

			# A URL to an icon representing this module.
			# The specified icon is displayed on the gallery webpage for the module
			IconUri = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/docs/Screenshots/bluewall.png"

			# ReleaseNotes of this module
			# ReleaseNotes = ""

			# A PreRelease string that identifies the module as a prerelease version in online galleries.
			Prerelease = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/docs/CHANGELOG.md"

			# Flag to indicate whether the module requires explicit user acceptance for
			# install, update, or save.
			RequireLicenseAcceptance = $true

			# A list of external modules that this module is dependent upon.
			# ExternalModuleDependencies = @()
		} # End of PSData hashtable
	} # End of PrivateData hashtable

	# HelpInfo URI of this module
	# HelpInfoURI = "https://raw.githubusercontent.com/metablaster/WindowsFirewallRuleset/master/Modules/Ruleset.PolicyFileEditor/Ruleset.PolicyFileEditor_c321c0fc-a6d8-4251-8f71-c69d8a57ce8f_HelpInfo.xml"

	# Default prefix for commands exported from this module.
	# Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ""
}
