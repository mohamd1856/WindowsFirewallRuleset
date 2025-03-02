
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
Generates a log file name for logging functions

.DESCRIPTION
Generates a log file name composed of current date and appends to requested LogFile and Path.
The function checks if the path to log file exists, if not it creates a new log file.

.PARAMETER Path
Path to directory into which to write logs

.PARAMETER LogName
File label which precedes file date, ex. "Warning" or "Error"

.PARAMETER Header
If specified, this header message will be at the top of a log file.
This parameter is ignored for existing log files

.PARAMETER Overwrite
If specified, log file is overwritten if it exists.

.EXAMPLE
PS> Initialize-Log "C:\Logs" -LogName "Warning"

Warning_25.02.20.log

.EXAMPLE
PS> Initialize-Log "C:\Logs" -LogName "Warning" -Overwrite -Header "New header"

Warning_25.02.20.log
Overwrites previous log with new header.

.INPUTS
None. You cannot pipe objects to Initialize-Log

.OUTPUTS
[string] Full path to log file name

.NOTES
None.
#>
function Initialize-Log
{
	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([string])]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateScript( { (Test-Path -Path (Split-Path -Path $_ -Qualifier)) })]
		[SupportsWildcards()]
		[System.IO.DirectoryInfo] $Path,

		[Parameter(Mandatory = $true)]
		[string] $LogName,

		[Parameter()]
		[string] $Header,

		[Parameter()]
		[switch] $Overwrite
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$Directory = Resolve-FileSystemPath $Path
	if (!$Directory)
	{
		Write-Error -Category InvalidResult -TargetObject $Path -Message "Unable to resolve path '$Path'"
		return $null
	}

	# Generate file name
	$FileName = $LogName + "_$(Get-Date -Format "dd.MM.yy").log"
	$LogFile = Join-Path -Path $Directory -ChildPath $FileName

	# Create Logs directory if it doesn't exist
	if (!$Directory.Exists)
	{
		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating log directory '$Directory'"
		$Directory.Create()
	}

	if (Test-Path -PathType Leaf -Path $LogFile)
	{
		if ($Overwrite)
		{
			Remove-Item -LiteralPath $LogFile
		}
		else
		{
			if (![string]::IsNullOrEmpty($Header))
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Header parameter is valid for new log files only, ignored..."
			}

			Write-Debug -Message "[$($MyInvocation.InvocationName)] Logs directory is '$Directory'"
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Log file name is '$FileName'"
			return $LogFile
		}
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Creating new log file '$FileName'"
	New-Item -ItemType File -Path $LogFile -ErrorAction Stop | Out-Null
	Set-Content -Path $LogFile -Value "`n#`n# Windows Firewall Ruleset $ProjectVersion"

	if ([string]::IsNullOrEmpty($Header))
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Log header is missing or invalid"
	}
	else
	{
		Add-Content -Path $LogFile -Value "# $Header"
	}

	Add-Content -Path $LogFile -Value "#`n"

	return $LogFile
}
