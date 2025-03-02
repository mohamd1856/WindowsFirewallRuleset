---
external help file: Ruleset.Remote-help.xml
Module Name: Ruleset.Remote
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-WinRMServer.md
schema: 2.0.0
---

# Disable-WinRMServer

## SYNOPSIS

Disable WinRM server for CIM and PowerShell remoting

## SYNTAX

### Default (Default)

```powershell
Disable-WinRMServer [-KeepDefault] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### All

```powershell
Disable-WinRMServer [-All] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Disable WinRM server for remoting previously enabled by Enable-WinRMServer.
WinRM service will continue to run but will accept only loopback HTTP and only if
using "LocalFirewall.PSedition" session configuration.

In addition unlike Disable-PSRemoting, it will also remove default firewall rules
and restore registry setting which restricts remote access to members of the
Administrators group on the computer.

## EXAMPLES

### EXAMPLE 1

```powershell
Disable-WinRMServer
```

### EXAMPLE 2

```powershell
Disable-WinRMServer -KeepDefault
```

### EXAMPLE 3

```powershell
Disable-WinRMServer -All
```

## PARAMETERS

### -All

If specified, will disable WinRM service completely including loopback functionality,
remove all listeners, disable all session configurations and disable registry setting to
deny remote access to Administrators

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepDefault

If specified, keeps default session configurations enabled.
This is needed to be able to specify -ComputerName parameter in commands that support it

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Disable-WinRMServer

## OUTPUTS

### None. Disable-WinRMServer does not generate any output

## NOTES

TODO: How to control language?
in WSMan:\COMPUTER\Service\DefaultPorts and
WSMan:\COMPUTERService\Auth\lang (-Culture and -UICulture?)
TODO: Parameter to apply only additional config as needed instead of hard reset all options (-Strict)
HACK: Set-WSManInstance fails in PS Core with "Invalid ResourceURI format" error
TODO: Implement -NoServiceRestart parameter if applicable so that only configuration is affected
See also output of: winrm get winrm/config

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-WinRMServer.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Remote/Help/en-US/Disable-WinRMServer.md)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management](https://docs.microsoft.com/en-us/powershell/module/microsoft.wsman.management)

[https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management](https://docs.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management)

[https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_session_configurations)
