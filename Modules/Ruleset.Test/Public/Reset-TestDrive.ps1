
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
Remove all items from test drive

.DESCRIPTION
Test drive is directory where unit tests may output their temporary data.
This function clears test directory leaving only test drive root directory.
If the test drive does not exist new one is created.
For safety reasons, when non default test drive is specified the function will complete operation
only if run as standard user, in which case it prompts for confirmation.

.PARAMETER Path
Test drive location.
The default is "TestDrive" directory inside well known test directory in repository.

.PARAMETER Retry
Specify the number of times this function will repeat an attempt to clear test drive.
This is needed in cases such as when contents are in use by another process.
The default is 2.

.PARAMETER Timeout
The timeout interval (in milliseconds) between each retry attempt.
The default is 1 second.

.PARAMETER Force
Skip prompting clearing non default test drive.
This parameter has no effect if the function is run as Administrator.

.EXAMPLE
PS> Reset-TestDrive

.EXAMPLE
PS> Reset-TestDrive "C:\PathTo\TestDrive"

.EXAMPLE
PS> Reset-TestDrive "C:\PathTo\TestDrive" -Retry 5 -Timeout 20000 -Force

.INPUTS
None. You cannot pipe objects to Reset-TestDrive

.OUTPUTS
None. Reset-TestDrive does not generate any output

.NOTES
TODO: Path supports wildcards
#>
function Reset-TestDrive
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Reset-TestDrive.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[System.IO.DirectoryInfo] $Path = $DefaultTestDrive,

		[Parameter()]
		[ValidateRange(0, [int32]::MaxValue)]
		[int32] $Retry = 2,

		[Parameter()]
		[ValidateRange(0, [int32]::MaxValue)]
		[int32] $Timeout = 1000,

		[Parameter()]
		[switch] $Force
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	if ($PSCmdlet.ShouldProcess($Path, "Recursively delete test drive"))
	{
		if ($Path.FullName -ne "$ProjectRoot\Test\TestDrive")
		{
			$Principal = New-Object -TypeName Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
			$StandardUser = Get-GroupPrincipal Users | Where-Object -Property Principal -EQ $Principal.Identities.Name

			if (!$StandardUser)
			{
				Write-Error -Category PermissionDenied -TargetObject $Principal `
					-Message "This operation requires standard user privileges"
				return
			}

			if ($Force)
			{
				Write-Warning -Message "[$($MyInvocation.InvocationName)] Recursive delete of test drive '$Path'"
			}
			elseif (!$PSCmdlet.ShouldContinue($Path, "Recursive delete of non default test drive"))
			{
				return
			}
		}

		if ($Path.Exists)
		{
			$Count = 0
			# NOTE: Increment because parameter variable must not go negative
			# This is offset in catch by comparing Retry to -gt 0 instead of -ge 0
			++$Retry
			while ($Retry -ge 0)
			{
				try
				{
					Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Resetting test drive"

					Get-ChildItem -Path $Path -File | ForEach-Object {
						Remove-Item -Path $_.FullName -ErrorAction Stop
					}

					Get-ChildItem -Path $Path -Directory | ForEach-Object {
						Remove-Item -Path $_.FullName -Recurse -ErrorAction Stop
					}

					break
				}
				catch [System.UnauthorizedAccessException]
				{
					# TODO: Maybe Set-Permission here?
					Write-Error -ErrorRecord $_
					return
				}
				catch
				{
					if (--$Retry -gt 0)
					{
						++$Count
						Write-Warning -Message "[$($MyInvocation.InvocationName)] Retrying ($Count) test drive reset: $($_.Exception.Message)"

						Start-Sleep -Milliseconds $Timeout
						continue
					}
					else
					{
						Write-Error -ErrorRecord $_
						return
					}
				}
			}
		}
		else
		{
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Generating new test drive"

			New-Item -Path $Path -ItemType Directory | Out-Null
		}

		$ReadmeData = @"

# TestDrive directory

Test drive is auto generated directory which may contain unit test results.\
Do not save anything here because directory contents may get lost.

"@

		if (!(Test-Path -Path $Path\README.md -PathType Leaf))
		{
			New-Item -Path $Path\README.md -ItemType File | Out-Null
		}

		Set-Content -Path $Path\README.md -Value $ReadmeData -Encoding $DefaultEncoding
	}
}
