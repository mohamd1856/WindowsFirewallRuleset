
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
Set vertical screen buffer to recommended value

.DESCRIPTION
Set-ScreenBuffer sets screenbuffer for current powershell session.
In some cases, depending on project settings a user might need larger buffer
to preserve all the output in the console for review and scroll back.

.PARAMETER Height
New screen buffer height

.EXAMPLE
PS> Set-ScreenBuffer

.EXAMPLE
PS> Set-ScreenBuffer 1000

.INPUTS
None. You cannot pipe objects to Set-ScreenBuffer

.OUTPUTS
None. Set-ScreenBuffer does not generate any output

.NOTES
TODO: A parameter to restore previous value may be useful

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-ScreenBuffer.md

.LINK
https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.host.pshostrawuserinterface
#>
function Set-ScreenBuffer
{
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High",
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Utility/Help/en-US/Set-ScreenBuffer.md")]
	[OutputType([void])]
	param (
		[Parameter()]
		[uint32] $Height = 3000
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] Caller = $((Get-PSCallStack)[1].Command) ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"

	$psHost = Get-Host
	$psWindow = $psHost.UI.RawUI
	$NewSize = $psWindow.BufferSize

	if ($NewSize.Height -lt $Height)
	{
		Write-Warning -Message "[$($MyInvocation.InvocationName)] Your screen buffer of $($NewSize.Height) is below recommended $Height to preserve all execution output"

		if ($PSCmdlet.ShouldProcess((Get-Host).Name, "Increase Screen Buffer"))
		{
			$NewSize.Height = $Height
			$psWindow.BufferSize = $NewSize
			Write-Information -Tags $MyInvocation.InvocationName -MessageData "INFO: Screen buffer changed to $Height"
			return
		}

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Setting screen buffer canceled"
		return
	}

	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Screen buffer check OK"
}
