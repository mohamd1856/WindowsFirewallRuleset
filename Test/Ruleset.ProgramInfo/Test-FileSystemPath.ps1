
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
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
Unit test for Test-FileSystemPath

.DESCRIPTION
Test correctness of Test-FileSystemPath function

.EXAMPLE
PS> .\Test-FileSystemPath.ps1

.INPUTS
None. You cannot pipe objects to Test-FileSystemPath.ps1

.OUTPUTS
None. Test-FileSystemPath.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1
New-Variable -Name ThisScript -Scope Private -Option Constant -Value ((Get-Item $PSCommandPath).Basename)

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\ContextSetup.ps1

# User prompt
Update-Context $TestContext $ThisScript
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

Enter-Test

#
# Root drives
#

New-Section "Root drive"

$TestPath = "C:"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath -PathType Directory

$TestPath = "C:\\"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "D:\"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "Z:\"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

#
# Expanded paths
#

New-Section "Expanded paths"

$TestPath = "C:\\Windows\System32"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "C:/Windows/explorer.exe"
Start-Test "Test-FileSystemPath -PathType Leaf: $TestPath"
Test-FileSystemPath $TestPath -PathType File

$TestPath = "C:\\NoSuchFolder"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

#
# Environment variables
#

New-Section "Environment variables"

$TestPath = "%SystemDrive%"
Start-Test "Test-FileSystemPath: $TestPath"
$Status = Test-FileSystemPath $TestPath
$Status

$TestPath = "C:\Program Files (x86)\Windows Defender\"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "%Path%"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "%SystemDrive%\Windows\%ProgramFiles%"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

#
# Bad syntax
#

New-Section "Invalid syntax"

$TestPath = '"C:\ProgramData\ssh"'
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "'C:\Windows\Microsoft.NET\Framework64\v3.5'"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "C:\Unk[n]own\*tory"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "C:\Bad\<Path>\Loca'tion"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

#
# Users folder
#

New-Section "Users folder"

$TestPath = "C:\Users"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

# TODO: 3 or more of \
$TestPath = "C:\Users\\"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

$TestPath = "C:\\UsersA\"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

$TestPath = "C:\\Users\3"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

$TestPath = "C:\Users\Public\Downloads" # "\Public Downloads"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

$TestPath = "C:\Users\\"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

$TestPath = "C:\\UsersA\"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

$TestPath = "C:\\Users\3"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

#
# User profile
#

New-Section "UserProfile"

$TestPath = "%LOCALAPPDATA%\Temp"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "%LOCALAPPDATA%\Temp"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

$TestPath = "F:\Users\$TestUser"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "F:\Users\$TestUser"
Start-Test "Test-FileSystemPath -UserProfile: $TestPath"
Test-FileSystemPath -UserProfile $TestPath

#
# Firewall switch
#

New-Section "Test firewall"

$TestPath = "C:\\Windows\System32"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

$TestPath = "%LOCALAPPDATA%\Temp"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

$TestPath = "C:\Users\Public\Downloads" # "\Public Downloads"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

$TestPath = "F:\Users\$TestUser"
Start-Test "Test-FileSystemPath -Firewall: $TestPath"
Test-FileSystemPath -Firewall $TestPath

#
# Firewall and UserProfile switch
#

New-Section "-Firewall + -UserProfile"

$TestPath = "%HOME%\AppData\Local\MicrosoftEdge"
Start-Test "Test-FileSystemPath -Firewall -UserProfile: $TestPath"
Test-FileSystemPath -Firewall -UserProfile $TestPath

$TestPath = "C:\Users\$TestUser\AppData"
Start-Test "Test-FileSystemPath -Firewall -UserProfile: $TestPath"
Test-FileSystemPath -Firewall -UserProfile $TestPath

$TestPath = "C:\Program Files (x86)\Windows Defender"
Start-Test "Test-FileSystemPath -Firewall -UserProfile: $TestPath"
Test-FileSystemPath -Firewall -UserProfile $TestPath

$TestPath = "%HOMEPATH%\AppData\Local\Temp"
Start-Test "Test-FileSystemPath -Firewall -UserProfile: $TestPath"
Test-FileSystemPath -Firewall -UserProfile $TestPath

$TestPath = "C:\Users\\"
Start-Test "Test-FileSystemPath -Firewall -UserProfile: $TestPath"
Test-FileSystemPath -Firewall -UserProfile $TestPath

$TestPath = "C:\Users\Public"
Start-Test "Test-FileSystemPath -Firewall -UserProfile: $TestPath"
Test-FileSystemPath -Firewall -UserProfile $TestPath

#
# Null or empty string
#

New-Section "Null test"

$TestPath = ""
Start-Test "Test-FileSystemPath: '$TestPath'"
Test-FileSystemPath $TestPath

$TestPath = $null
Start-Test "Test-FileSystemPath: null"
$Status = Test-FileSystemPath $TestPath
$Status

Test-Output $Status -Command Test-FileSystemPath

#
# Relative paths
#

New-Section "Relative paths"

$TestPath = ".\.."
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "."
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "\"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "C:\Windows\System32\..\regedit.exe"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

#
# Not file system
#

$TestPath = "HKLM:\SOFTWARE\Microsoft\Clipboard"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

$TestPath = "\\COMPUTERNAME\Directory\file.exe"
Start-Test "Test-FileSystemPath: $TestPath"
Test-FileSystemPath $TestPath

Test-Output $Status -Command Test-FileSystemPath

Update-Log
Exit-Test
