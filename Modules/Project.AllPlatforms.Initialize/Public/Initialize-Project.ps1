
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Test and print system requirements required for this project
.DESCRIPTION
Initialize-Project is designed for "Windows Firewall Ruleset", it first prints a short watermark,
tests for OS, PowerShell version and edition, Administrator mode, NET Framework version, checks if
required system services are started and recommended modules installed.
If not the function may exit and stop executing scripts.
.PARAMETER Check
true or false to check or not to check
note that this parameter is managed by project settings
.EXAMPLE
Initialize-Project
.INPUTS
None. You cannot pipe objects to Initialize-Project
.OUTPUTS
None. Error or warning message is shown if check failed, system info otherwise.
.NOTES
TODO: learn required NET version by scanning scripts (ie. adding .COMPONENT to comments)
TODO: learn repo dir automatically (using git?)
TODO: we don't use logs in this module
TODO: remote check not implemented
#>
function Initialize-Project
{
	[OutputType([void])]
	param (
		[Parameter()]
		[switch] $NoProjectCheck = !$ProjectCheck,

		[Parameter()]
		[switch] $NoModulesCheck = !$ModulesCheck,

		[Parameter()]
		[switch] $NoServicesCheck = !$ServicesCheck
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	# disabled when running scripts from SetupFirewall.ps1 script
	if ($NoProjectCheck)
	{
		Write-Debug -Message "[$($MyInvocation.InvocationName)] Project initialization skipped"
		return
	}

	# Print watermark
	Write-Output ""
	Write-Output "Windows Firewall Ruleset v$($ProjectVersion.ToString())"
	Write-Output "Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch"
	Write-Output "https://github.com/metablaster/WindowsFirewallRuleset"
	Write-Output ""

	Write-Information -Tags "User" -MessageData "INFO: Checking operating system"

	# Check operating system
	$OSPlatform = [System.Environment]::OSVersion.Platform
	[version] $TargetOSVersion = [System.Environment]::OSVersion.Version
	[version] $RequiredOSVersion = "10.0"

	if (!(($OSPlatform -eq "Win32NT") -and ($TargetOSVersion -ge $RequiredOSVersion)))
	{
		Write-Error -Category OperationStopped -TargetObject $TargetOSVersion `
			-Message "Minimum required operating system is 'Win32NT $($RequiredOSVersion.ToString())' but '$OSPlatform $($TargetOSVersion.ToString()) present"
		exit
	}

	Write-Information -Tags "User" -MessageData "INFO: Checking elevation"

	# Check if in elevated PowerShell
	$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

	if (!$Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		Write-Error -Category PermissionDenied -TargetObject $Principal `
			-Message "Elevation required, please open PowerShell as Administrator and try again"
		exit
	}

	Write-Information -Tags "User" -MessageData "INFO: Checking OS edition"

	# Check OS is not Home edition
	$OSEdition = Get-WindowsEdition -Online | Select-Object -ExpandProperty Edition

	if ($OSEdition -like "*Home*")
	{
		Write-Error -Category OperationStopped -TargetObject $OSEdition `
			-Message "Home editions of Windows don't have Local Group Policy"
		exit
	}

	Write-Information -Tags "User" -MessageData "INFO: Checking PowerShell edition"

	# Check PowerShell edition
	$PowerShellEdition = $PSVersionTable.PSEdition
	# Check PowerShell version
	[version] $RequiredPSVersion = "5.1.0"
	[version] $TargetPSVersion = $PSVersionTable.PSVersion

	if ($PowerShellEdition -eq "Core")
	{
		$RequiredPSVersion = "7.0.3"
		Write-Warning -Message "Remote firewall administration with PowerShell Core is not implemented"
	}
	else
	{
		Write-Warning -Message "Remote firewall administration with PowerShell Desktop is partially implemented"

	}

	Write-Information -Tags "User" -MessageData "INFO: Checking PowerShell version"
	if ($TargetPSVersion -lt $RequiredPSVersion)
	{
		if ($TargetPSVersion.Major -lt $RequiredPSVersion.Major)
		{
			# Core 6 is fine
			if (($PowerShellEdition -eq "Desktop") -or (($RequiredPSVersion.Major - $TargetPSVersion.Major) -gt 1))
			{
				Write-Error -Category OperationStopped -TargetObject $TargetPSVersion `
					-Message "Required PowerShell $PowerShellEdition is v$($RequiredPSVersion.ToString()) but v$($TargetPSVersion.ToString()) present"
				exit
			}
		}

		Write-Warning -Message "Recommended PowerShell $PowerShellEdition is v$($RequiredPSVersion.ToString()) but v$($TargetPSVersion.ToString()) present"
	}

	# Check NET Framework version
	# NOTE: this check is not required except for updating requirements as needed
	if ($Develop -and ($PowerShellEdition -eq "Desktop"))
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking .NET version"

		# Now that OS and PowerShell is OK we can use these functions
		$NETFramework = Get-NetFramework
		[version] $TargetNETVersion = $NETFramework |
		Sort-Object -Property Version | Select-Object -Last 1 -ExpandProperty Version

		[version] $RequiredNETVersion = "3.5.0"

		if (!$TargetNETVersion -or ($TargetNETVersion -lt $RequiredNETVersion))
		{
			Write-Error -Category OperationStopped -TargetObject $TargetNETVersion `
				-Message "Minimum required .NET Framework version is v$($RequiredNETVersion.ToString()) but v$($TargetNETVersion.ToString()) present"
			exit
		}
	}

	if (!$NoServicesCheck)
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking system services"

		# These services are minimum required
		if (!(Initialize-Service @("lmhosts", "LanmanWorkstation", "LanmanServer"))) { exit }

		# NOTE: remote administration needs this service, see Enable-PSRemoting cmdlet
		# NOTE: some tests depend on this service, project not ready for remoting
		if ($develop -and ($PolicyStore -ne [System.Environment]::MachineName))
		{
			if (Initialize-Service "WinRM") { exit }
		}
	}

	Write-Information -Tags "User" -MessageData "INFO: Checking git"

	# Git is recommended for version control and by posh-git module
	[string] $RequiredGit = "2.28.0"
	Set-Variable -Name GitInstance -Scope Script -Option Constant -Value `
	$(Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue)

	if ($GitInstance)
	{
		[version] $TargetGit = $GitInstance.Version

		if ($TargetGit -lt $RequiredGit)
		{
			Write-Warning -Message "Git version v$($TargetGit.ToString()) is out of date, recommended version is v$RequiredGit"
			Write-Information -Tags "Project" -MessageData "INFO: Please visit https://git-scm.com to download and update"
		}
	}
	else
	{
		Write-Warning -Message "Git in the PATH minimum version v$($RequiredGit.ToString()) is recommended but missing"
		Write-Information -Tags "User" -MessageData "INFO: Please verify PATH or visit https://git-scm.com to download and install"
	}

	if (!$NoModulesCheck)
	{
		Write-Information -Tags "User" -MessageData "INFO: Checking providers"

		[string] $Repository = "NuGet"

		# NOTE: Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider
		# NOTE: Updating PackageManagement and PowerShellGet requires restarting PowerShell to switch to the latest version.
		if (!(Initialize-Provider @{ ModuleName = "NuGet"; ModuleVersion = "3.0.0" } `
					-InfoMessage "Before updating PowerShellGet or PackageManagement, you should always install the latest Nuget provider")) { exit }

		Write-Information -Tags "User" -MessageData "INFO: Checking modules"

		# PowerShellGet >= 2.2.4 is required otherwise updating modules might fail
		# NOTE: PowerShellGet has a dependency on PackageManagement, it will install it if needed
		# For systems with PowerShell 5.0 (or greater) PowerShellGet and PackageManagement can be installed together.
		if (!(Initialize-Module @{ ModuleName = "PowerShellGet"; ModuleVersion = "2.2.4" } -Repository $Repository `
					-InfoMessage "PowerShellGet >= 2.2.4 is required otherwise updating modules might fail")) { exit }

		# PackageManagement >= 1.4.7 is required otherwise updating modules might fail
		if (!(Initialize-Module @{ ModuleName = "PackageManagement"; ModuleVersion = "1.4.7" } -Repository $Repository)) { exit }

		# posh-git >= 1.0.0-beta4 is recommended for better git experience in PowerShell
		if (Initialize-Module @{ ModuleName = "posh-git"; ModuleVersion = "0.7.3" } -Repository $Repository -AllowPrerelease `
				-InfoMessage "posh-git is recommended for better git experience in PowerShell" ) { }

		# PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing
		if (!(Initialize-Module @{ ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.19.1" } -Repository $Repository `
					-InfoMessage "PSScriptAnalyzer >= 1.19.1 is required otherwise code will start missing while editing" )) { exit }

		# Pester is required to run pester tests
		if (!(Initialize-Module @{ ModuleName = "Pester"; ModuleVersion = "5.0.3" } -Repository $Repository `
					-InfoMessage "Pester is required to run pester tests" )) { }
	}

	# Everything OK, print environment status
	# TODO: CIM may not always work
	$OSCaption = Get-CimInstance -Class Win32_OperatingSystem |
	Select-Object -ExpandProperty Caption

	Write-Information -Tags "User" -MessageData "INFO: Checking project requirements successful"

	Write-Output ""
	Write-Output "System:`t`t $OSCaption v$($TargetOSVersion.ToString())"
	Write-Output "Environment:`t PowerShell $PowerShellEdition v$($TargetPSVersion)"
	Write-Output ""
}
