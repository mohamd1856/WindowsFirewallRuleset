---
external help file: Ruleset.Compatibility-help.xml
Module Name: Ruleset.Compatibility
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Add-WinFunction.md
schema: 2.0.0
---

# Add-WinFunction

## SYNOPSIS

This command defines a global function that always runs in the compatibility session

## SYNTAX

```powershell
Add-WinFunction [-Name] <String> [-ScriptBlock] <ScriptBlock> [-Domain <String>] [-ConfigurationName <String>]
 [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This command defines a global function that always runs in the compatibility session,
returning serialized data to the calling session.
Parameters can be specified using the "param" statement but only positional parameters are supported.

By default, when executing, the current compatibility session is used,
or, in the case where there is no existing session, a new default session will be created.
This behavior can be overridden using the additional parameters on the command.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-WinFunction myFunction {param ($n) "Hi $n!"; $PSVersionTable.PSEdition }
PS> myFunction Bill
```

Hi Bill!
Desktop

This example defines a function called "myFunction" with 1 parameter.
When invoked it will print a message then return the PSVersion table from the compatibility session.

## PARAMETERS

### -Name

The name of the function to define

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: FunctionName

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock

Scriptblock to use as the body of the function

```yaml
Type: System.Management.Automation.ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

If you don't want to use the default compatibility session, use this parameter to specify the name
of the computer on which to create the compatibility session.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationName

Specifies the configuration to connect to when creating the compatibility session
(Defaults to "Microsoft.PowerShell")

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

The credential to use when creating the compatibility session using the target machine/configuration

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Add-WinFunction

## OUTPUTS

### None. Add-WinFunction does not generate any output

## NOTES

The Following modifications by metablaster November 2020:

- Added comment based help based on original comments
- Code formatting according to the rest of project design
- Replace double quotes with single quotes
- Added HelpURI link to project location

January 2021:

- Replace cast to \[void\] with Out-Null
- Added parameter debugging stream

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Add-WinFunction.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Compatibility/Help/en-US/Add-WinFunction.md)

[https://github.com/PowerShell/WindowsCompatibility](https://github.com/PowerShell/WindowsCompatibility)
