
# Remoting help

This document briefly describes remoting commandlets, requirements, help notices and
design used in this repository.

## Table of Contents

- [Remoting help](#remoting-help)
  - [Table of Contents](#table-of-contents)
  - [Commandlets breakdown](#commandlets-breakdown)
    - [Set-WSManQuickConfig](#set-wsmanquickconfig)
    - [Enable-PSRemoting](#enable-psremoting)
    - [Enable-PSSessionConfiguration](#enable-pssessionconfiguration)
    - [Disable-PSRemoting](#disable-psremoting)
    - [Disable-PSSessionConfiguration](#disable-pssessionconfiguration)
    - [WinRM on loopback](#winrm-on-loopback)
    - [Security descriptor flags](#security-descriptor-flags)
    - [SkipNetworkProfileCheck commandlets](#skipnetworkprofilecheck-commandlets)
  - [Remote registry](#remote-registry)
    - [Remote registry requirements in PowerShell](#remote-registry-requirements-in-powershell)
    - [Exception handling](#exception-handling)
  - [Troubleshooting](#troubleshooting)
    - [Troubleshooting WinRM](#troubleshooting-winrm)
      - [The WinRM client sent a request to an HTTP server and got a response saying the requested HTTP URL was not available](#the-winrm-client-sent-a-request-to-an-http-server-and-got-a-response-saying-the-requested-http-url-was-not-available)
      - ["Negotiate" authentication is not enabled](#negotiate-authentication-is-not-enabled)
      - [Encountered an internal error in the SSL library](#encountered-an-internal-error-in-the-ssl-library)
      - [Access is denied (WinRM)](#access-is-denied-winrm)
    - [Troubleshooting CIM](#troubleshooting-cim)
      - [WS-Management service does not support the specified polymorphism mode](#ws-management-service-does-not-support-the-specified-polymorphism-mode)
      - [The service is configured to reject remote connection requests for this plugin](#the-service-is-configured-to-reject-remote-connection-requests-for-this-plugin)
      - [Access is denied (CIM)](#access-is-denied-cim)
    - [Troubleshooting remote registry](#troubleshooting-remote-registry)
  - [Remoting status](#remoting-status)
    - [Ruleset.Compatibility](#rulesetcompatibility)
    - [Ruleset.ComputerInfo](#rulesetcomputerinfo)
    - [Ruleset.Firewall](#rulesetfirewall)
    - [Ruleset.ProgramInfo](#rulesetprograminfo)
    - [Ruleset.Remote](#rulesetremote)
    - [Ruleset.UserInfo](#rulesetuserinfo)
    - [Ruleset.Utility](#rulesetutility)
    - [Scripts](#scripts)

## Commandlets breakdown

A brief breakdown that is of interest, according to Microsoft docs.

### Set-WSManQuickConfig

- Starts the WinRM service and sets startup type to automatic.
- Creates a listener to accept requests on any IP address, HTTP by default.
- Adds `Windows Remote Management` firewall rules to PersistentStore (required by WinRM)

[Reference][Set-WSManQuickConfig]

`Set-WSManQuickConfig -UseSSL` will not work if your certificate is self signed

[Table of Contents](#table-of-contents)

### Enable-PSRemoting

- Runs the `Set-WSManQuickConfig`
- Creates (or recreates) the default session configurations.
- Enables all session configurations, see [Enable-PSSessionConfiguration](#enable-pssessionconfiguration)
- Changes the security descriptor of all session configurations to allow remote access.
  - Removes the `Deny_All`
  - Removes the `Network_Deny_All`
- Sets the following registry key to `1`\
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LocalAccountTokenFilterPolicy`
- Restarts the WinRM service

This provides remote access to session configurations that were reserved for local use.\
`LocalAccountTokenFilterPolicy = 1` allows remote access to members of the Administrators group.

[Reference][Enable-PSRemoting]\
[Table of Contents](#table-of-contents)

### Enable-PSSessionConfiguration

- Removes the `Deny_All` setting from the security descriptor
- Turns on the listener that accepts requests on any IP address
- Restarts the WinRM service
- Sets the value of the Enabled property of the session configuration in\
`WSMan:\<computer>\PlugIn\<SessionConfigurationName>\Enabled` to True.

Does not remove or change the `Network_Deny_All`

[Reference][Enable-PSSessionConfiguration]\
[Table of Contents](#table-of-contents)

### Disable-PSRemoting

Changes the security descriptor of all session configurations to block remote access

- Adds the `Network_Deny_All`

Will **not** undo the following:

- Stop and disable the WinRM service
- Delete the listener that accepts requests on any IP address
- Disable and remove  `Windows Remote Management` firewall rules (including compatibility rules)
- Add `Deny_All` if it was present previously
- Restore the following registry value to `0`\
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LocalAccountTokenFilterPolicy`

`LocalAccountTokenFilterPolicy = 0` blocks remote access to members of the Administrators group.

Because `Deny_All` was not added, loopback connections are still allowed, for requirements see
[WinRM on loopback](#winrm-on-loopback)

[Reference][Disable-PSRemoting]\
[Table of Contents](#table-of-contents)

### Disable-PSSessionConfiguration

- Adds the `Deny_All` setting to the security descriptor
- Sets the value of the Enabled property of the session configuration in\
`WSMan:\<computer>\PlugIn\<SessionConfigurationName>\Enabled` to False.

[Table of Contents](#table-of-contents)

### WinRM on loopback

A loopback connection is created when the following conditions are met:

- The computer name to connect to is `localhost`
- No credentials are passed in
- Current logged in user (implicit credentials) is used for the connection
- The `-EnableNetworkAccess` switch parameter is used with `New-PSSession`

For loopback remoting reference see [Disable-PSRemoting][Disable-PSRemoting]

[Table of Contents](#table-of-contents)

### Security descriptor flags

- `Deny_All` block all users from using session configuration, both remote and local
- `Network_Deny_All` allow only users of the local computer to use the session configuration,
either loopback or trough network stack

For details see `-AccessMode` parameter description here [AccessMode][descriptor flags]

To add or remove these flags to configurations manually use [Set-PSSessionConfiguration][set descriptor]

[Table of Contents](#table-of-contents)

### SkipNetworkProfileCheck commandlets

`-SkipNetworkProfileCheck` switch parameter is available only by the following commandlets:

- `Set-WSManQuickConfig`
- `Enable-PSRemoting`
- `Enable-PSSessionConfiguration`

If you have Hyper-V installed that means some virtual switches will operate on public network even
if you're on private network profile, which means you won't be able to configure all possible WinRM
service options, except only with those commandlets listed above.

Disabling those virtual switches is required in that case, uninstalling Hyper-V is an alternative
solution if disabling does not work.

Of course any remaining network adapters must operate on private network profile.

For reference see `-SkipNetworkProfileCheck` parameter description.

[Table of Contents](#table-of-contents)

## Remote registry

In this repository for PowerShell `[Microsoft.Win32.RegistryKey]` class is used for remote registry.

For reference see [RegistryKey][RegistryKey]

[Table of Contents](#table-of-contents)

### Remote registry requirements in PowerShell

The following requirements apply to both endpoints involved (client and server computers):

- `RemoteRegistry` service is set to `Manual (Trigger Start)` startup on both endpoints
- Enable at a minimum the following **predefined** (not custom) firewall rules:
  - `File and Printer sharing`
  - `Network Discovery`
- Network adapter is on `Private` or `Domain` network profile on both endpoints.

To initiate remote registry connection you must authenticate to remote computer with username and
password of the user account on remote computer that belongs to `Administrators` group.

`[Microsoft.Win32.RegistryKey]` does not provide any authentication methods, therefore to use it in
PowerShell the solution is to open network drive as follows:

```powershell
$RemoteComputer = "COMPUTERNAME"
$RemotingCredential = Get-Credential

New-PSDrive -Credential $RemotingCredential -PSProvider FileSystem -Name RemoteRegistry `
    -Root \\$RemoteComputer\C$ -Description "Remote registry authentication" | Out-Null
```

Note that Registry provider `-PSProvider Registry` does not support specifying credentials but
specifying `FileSystem` does the trick.

If `New-PSDrive` fails with "The network path was not found" try restarting `fdphost` service on
both computers or reboot both computers.\
Alternatively, creating a new remote share and authenticating to it instead of default `C$` can help.

[Table of Contents](#table-of-contents)

### Exception handling

Methods of the `[Microsoft.Win32.RegistryKey]` class may throw various exceptions but not all are
handled in this repository except for initial registry authentication and root key access to avoid
code bloat.

At a minimum you should handle `OpenRemoteBaseKey` and opening root key (but not subsequent subkeys)
with `OpenSubkey` exceptions.

The following is an example which you can copy\paste to problem script to get detailed problem description.

```powershell
try
{
    Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $RemoteComputer"
    $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $RemoteComputer, $RegistryView)
}
catch [System.UnauthorizedAccessException]
{
    Write-Error -Category AuthenticationError -TargetObject $RegistryHive -Message $_.Exception.Message
    Write-Warning -Message "[$($MyInvocation.InvocationName)] Remote registry access was denied for $([Environment]::MachineName)\$([Environment]::UserName) by $RemoteComputer system"
    return
}
catch [System.Security.SecurityException]
{
    Write-Error -Category SecurityError -TargetObject $RegistryHive -Message $_.Exception.Message
    Write-Warning -Message "[$($MyInvocation.InvocationName)] $($RemotingCredential.UserName) does not have the requested ACL permissions for $RegistryHive hive"
    return
}
catch
{
    Write-Error -ErrorRecord $_
    return
}

try
{
    Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key: HKLM:\$HKLM"
    $RootKey = $RemoteKey.OpenSubkey($HKLM, $RegistryPermission, $RegistryRights)

    if (!$RootKey)
    {
        throw [System.Data.ObjectNotFoundException]::new("The following registry key does not exist: HKLM:\$HKLM")
    }
}
catch [System.Security.SecurityException]
{
    Write-Error -Category SecurityError -TargetObject $HKLM -Message $_.Exception.Message
    Write-Warning -Message "[$($MyInvocation.InvocationName)] $($RemotingCredential.UserName) does not have the requested ACL permissions for $HKLM key"
}
catch
{
    Write-Error -ErrorRecord $_
}
finally
{
    if ($RemoteKey)
    {
        $RemoteKey.Dispose()
    }

    Write-Error -ErrorRecord $_
    return
}
```

For additional breakdown of registry key naming convention and exceptions see [NamingConvention.md](NamingConvention.md)

[Table of Contents](#table-of-contents)

## Troubleshooting

The following link lists common issues with remoting and how to troubleshoot them [About Remote Troubleshooting][troubleshooting]

The following section lists other not so common problems and how to resolve them.

### Troubleshooting WinRM

**TODO:** missing resolutions for the following known problems:

- System cannot find file because it does not exist

[Table of Contents](#table-of-contents)

#### The WinRM client sent a request to an HTTP server and got a response saying the requested HTTP URL was not available

> Connecting to remote server COMPUTERNAME failed with the following error message :
> The WinRM client sent a request to an HTTP server and got a response saying the requested HTTP URL
> was not available.
> This is usually returned by a HTTP server that does not support the WS-Management protocol.

When you specify computername, it is translated to private IP address for which listener must exist.\
WinRM service is not listening on the translated IP address, to add listener for any IP address run:

```powershell
New-Item -Path WSMan:\localhost\Listener -Address * -Transport HTTP -Enabled $true -Force | Out-Null
```

or alternatively:

```powershell
New-WSManInstance -ResourceURI winrm/config/Listener -ValueSet @{ Enabled = $true } `
     -SelectorSet @{ Address = "*"; Transport = "HTTP" } | Out-Null
```

[Table of Contents](#table-of-contents)

#### "Negotiate" authentication is not enabled

```powershell
Set-Item -Path WSMan:\localhost\Client\Auth\Negotiate -Value $true
Restart-Service -Name WinRM
```

If not working then:

```powershell
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client\ `
     -Name auth_negotiate -Value ([int32] ($AuthenticationOptions["Negotiate"] -eq $true))
Restart-Service -Name WinRM
```

[Table of Contents](#table-of-contents)

#### Encountered an internal error in the SSL library

> The server certificate on the destination computer (localhost) has the following errors:
> Encountered an internal error in the SSL library.

If using SSL on localhost, it would go trough network stack and for this you need authentication,
which means specifying host name, user name and password.

[Table of Contents](#table-of-contents)

#### Access is denied (WinRM)

> `Access is denied`

If credentials are required, this may happen due to invalid username\password.\
It may also happen if the administrative account used to deploy firewall has no password set,
in which case password must be set because WinRM doesn't support passwordless authentication.\
Although it should be possible for passwordless logon by configuring GPO on remote computer:\
`Computer Configuration/Windows Settings/Security Settings/Local Policies/Security Options/Accounts:`\
`Limit local account use of blank passwords to console logon only`

> [localhost] Connecting to remote server localhost failed with the following error message: Access is denied.

If this happens in `Initialize-WinSession` it's because session configuration was disabled in
Windows PowerShell, ex. by using `Reset-Firewall -Remoting`, to fix this problem run in Windows PowerShell:

```powershell
Set-PSSessionConfiguration -Name Microsoft.PowerShell -AccessMode Remote
```

Otherwise check the following 3 things:

1. Verify PS session configuration which is being used is enabled

    ```powershell
    Get-PSSessionConfiguration -Name "NameOfTheSession" | Enable-PSSessionConfiguration
    ```

    **NOTE:** To get Windows PowerShell session configurations use `Get-PSSessionConfiguration` in
    Windows PowerShell

2. Verify access mode of the session PS configuration is set to `Remote`

    ```powershell
    Set-PSSessionConfiguration -Name "NameOfTheSession" -AccessMode Remote
    ```

3. Verify `LocalAccountTokenFilterPolicy` is enabled (set to 1)

    ```powershell
    Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Value 1 `
        -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    ```

4. Verify access permissions for user or group on remote host per session in question

    ```powershell
    Set-PSSessionConfiguration -ShowSecurityDescriptorUI -Name NameOfTheSession
    ```

[Table of Contents](#table-of-contents)

### Troubleshooting CIM

The following sections list CIM related errors and how to resolve them

#### WS-Management service does not support the specified polymorphism mode

Error description example:

> Get-CimInstance: The WS-Management service does not support the specified polymorphism mode.
> Try changing the polymorphism mode specified, and try again.

Error resolution:

> The Web Services Management Protocol Extensions for Windows Vista service MUST return instances of
> both base and derived classes.
> Each returned instance MUST contain the properties of the base class.
> Each returned instance MAY omit the properties from the derived classes and MAY set the instance
> type of derived classes to the base class.

[PolymorphismMode][winrm polymorphism]

Hint: do not use `-Shallow` parameter with `Get-CimInstance` commandlet

#### The service is configured to reject remote connection requests for this plugin

> The WS-Management service cannot process the request.
> The service is configured to reject remote connection requests for this plugin

You get this error when running `Get-CimInstance -CimSession $CimServer` where `$CimServer` is
your already established remote CIM session.

First step is to harvest plugin status as follows:

```powershell
Get-Item WSMan:\localhost\Plugin\* | ForEach-Object {
  $Enabled = Get-Item "WSMan:\localhost\Plugin\$($_.Name)\Enabled" |
  Select-Object -ExpandProperty Value

  [PSCustomObject] @{
    Name = $_.Name
    Enabled = $Enabled
    PSPath = $_.PSPath
  }
} | Sort-Object -Property Enabled -Descending | Format-Table -AutoSize
```

Sample output may look like this:

```none
Name                          Enabled PSPath
----                          ------- ------
RemoteFirewall                True    Microsoft.WSMan.Management\WSMan::localhost\Plugin\RemoteFirewall
Microsoft.PowerShell          True    Microsoft.WSMan.Management\WSMan::localhost\Plugin\Microsoft.PowerShell
WMI Provider                  False   Microsoft.WSMan.Management\WSMan::localhost\Plugin\WMI Provider
Microsoft.PowerShell32        False   Microsoft.WSMan.Management\WSMan::localhost\Plugin\Microsoft.PowerShell32
Event Forwarding Plugin       False   Microsoft.WSMan.Management\WSMan::localhost\Plugin\Event Forwarding Plugin
Microsoft.Powershell.Workflow False   Microsoft.WSMan.Management\WSMan::localhost\Plugin\Microsoft.Powershell.Workflow
```

As you can see `WMI Provider` plugin is not enabled in this example which does the following:

> WMI allows you to manage local and remote computers and models computer and network objects using
> an extension of the Common Information Model (CIM) standard

Since this plugin is required to run CIM commands against remote computer you enable it like this:

```powershell
Set-Item -Path WSMan:\localhost\Plugin\"WMI Provider"\Enabled -Value $true
Restart-Service -Name WinRM
```

[Table of Contents](#table-of-contents)

For more information see [WMI plug-in configuration notes][WMI plugin]

#### Access is denied (CIM)

Most likely you need to specify credentials

[Table of Contents](#table-of-contents)

### Troubleshooting remote registry

See the following link [Troubleshooting Remote Registry][remote registry]

[Table of Contents](#table-of-contents)

## Remoting status

The following section lists module functions and scripts which support or do not support remoting
by design, as well as functions which currently lack remoting implementation or are unfinished for
remoting.

The following modules do no expose any remoting functionality at all by design

- Ruleset.Test
- Ruleset.Logging
- Ruleset.Initialize
- Ruleset.IP
- VSSetup

The following modules lack remoting functionality

- Ruleset.PolicyFileEditor

### Ruleset.Compatibility

The following functions support remoting but were not tested for remoting

- Add-WinFunction
- Compare-WinModule
- Copy-WinModule
- Get-WinModule
- Import-WinModule
- Initialize-WinSession
- Invoke-WinCommand

The following functions do not implement remoting and it's unclear if it's needed

- Add-WindowsPSModulePath

### Ruleset.ComputerInfo

The following functions support remoting

- Get-SystemSKU
- Test-Computer
- Select-IPInterface
- Get-InterfaceBroadcast

The following functions lack remoting implementation

- Get-InterfaceAlias

All other public functions do not support remoting by design

### Ruleset.Firewall

The following functions support remoting

- Get-RegistryRule
- Export-RegistryRule
- Export-FirewallSetting
- Import-FirewallRule
- Import-FirewallSetting
- Remove-FirewallRule

The following functions do not support remoting by design

- Format-RuleOutput

All other public functions lack remoting implementation

### Ruleset.ProgramInfo

The following functions do not support remoting by design

- Format-Path
- Get-AppSID

The following functions support remoting with PowerShell Core only

- Get-AppCapability
- Get-SystemApp
- Get-UserApp

All other public functions support remoting

### Ruleset.Remote

The following functions support remoting

- Connect-Computer
- Publish-SshKey
- Test-RemoteRegistry
- Test-WinRM

All other functions do not implement remoting and it's unclear if remoting is needed

### Ruleset.UserInfo

The following functions do not support remoting by design

- Merge-SDDL
- Split-Principal
- Test-SDDL
- Test-UPN

The following functions lack remoting implementation

- Test-Credential

The following functions support remoting but may fail

- ConvertFrom-SDDL

All other functions support remoting

### Ruleset.Utility

The following functions support remoting

- Invoke-Process
- Select-EnvironmentVariable
- Set-NetworkProfile

The following functions lack remoting implementation

- Set-Shortcut

All other functions do not support remoting by design

### Scripts

The following scripts support remoting

- Get-NetworkStat
- Deploy-ASR (Windows PS only)
- Show-ASR (Windows PS only)
- Confirm-Firewall (experimental)
- Complete-Firewall
- Deploy-Firewall
- Backup-Firewall
- Reset-Firewall
- Restore-Firewall

The following scripts lack remoting implementation

- Grant-Logs
- Find-UnsignedFile

All other scripts do not support remoting by design

[Table of Contents](#table-of-contents)

[Enable-PSRemoting]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting "Visit Microsoft docs"
[Set-WSManQuickConfig]: https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management/set-wsmanquickconfig  "Visit Microsoft docs"
[Enable-PSSessionConfiguration]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-pssessionconfiguration "Visit Microsoft docs"
[descriptor flags]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-pssessionconfiguration#parameters "Visit Microsoft docs"
[set descriptor]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-pssessionconfiguration "Visit Microsoft docs"
[Disable-PSRemoting]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/disable-psremoting "Visit Microsoft docs"
[winrm polymorphism]: https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-wsmv/474f8cfd-ad24-4b04-a946-d02eae8a4a2c "Visit Microsoft docs"
[troubleshooting]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting "Visit Microsoft docs"
[remote registry]: https://support.delphix.com/Delphix_Virtualization_Engine/MSSQL_Server/Troubleshooting_Remote_Registry_Read_Problems_During_Environment_Discoveries_And_Refreshes_(KBA1552) "Visit Microsoft docs"
[RegistryKey]: https://docs.microsoft.com/en-us/dotnet/api/microsoft.win32.registrykey "Visit Microsoft docs"
[WMI plugin]: https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management#wmi-plug-in-configuration-notes "Visit Microsoft docs"
