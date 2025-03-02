---
external help file: Ruleset.ComputerInfo-help.xml
Module Name: Ruleset.ComputerInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ComputerInfo/Help/en-US/Get-InterfaceAlias.md
schema: 2.0.0
---

# Get-InterfaceAlias

## SYNOPSIS

Get interface aliases of specified network adapters

## SYNTAX

### Domain (Default)

```powershell
Get-InterfaceAlias [-AddressFamily <String>] [-Domain <String>] [-Credential <PSCredential>]
 [-WildCardOption <WildcardOptions>] [-Physical] [-Virtual] [-Visible] [-Hidden] [-Connected]
 [<CommonParameters>]
```

### Session

```powershell
Get-InterfaceAlias [-AddressFamily <String>] [-Session <PSSession>] [-WildCardOption <WildcardOptions>]
 [-Physical] [-Virtual] [-Visible] [-Hidden] [-Connected] [<CommonParameters>]
```

## DESCRIPTION

Get a list of interface aliases of specified network adapters.
This function takes care of interface aliases with wildcard patterns, by replacing them with
escape codes which is required to create valid fiewall rule based on interface alias.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-InterfaceAlias -AddressFamily IPv4
```

### EXAMPLE 2

```powershell
Get-InterfaceAlias -AddressFamily IPv4 -Physical
```

### EXAMPLE 3

```powershell
Get-InterfaceAlias -AddressFamily IPv6 -WildcardOption "IgnoreCase"
```

## PARAMETERS

### -AddressFamily

Obtain interface aliases configured for specific IP version

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: IPVersion

Required: False
Position: Named
Default value: Any
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain

Computer name from which to obtain interface aliases

```yaml
Type: System.String
Parameter Sets: Domain
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specifies the credential object to use for authentication

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: Domain
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Specifies the PS session to use

```yaml
Type: System.Management.Automation.Runspaces.PSSession
Parameter Sets: Session
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WildCardOption

Specify wildcard options that modify the wildcard patterns found in interface alias strings.
Compiled:
The wildcard pattern is compiled to an assembly.
This yields faster execution but increases startup time.
CultureInvariant:
Specifies culture-invariant matching.
IgnoreCase:
Specifies case-insensitive matching.
None:
Indicates that no special processing is required.

```yaml
Type: System.Management.Automation.WildcardOptions
Parameter Sets: (All)
Aliases:
Accepted values: None, Compiled, IgnoreCase, CultureInvariant

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Physical

If specified, include only physical adapters

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Virtual

If specified, include only virtual adapters

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Visible

If specified, only visible interfaces are included

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hidden

If specified, only hidden interfaces are included

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Connected

If specified, only interfaces connected to network are returned

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. You cannot pipe objects to Get-InterfaceAlias

## OUTPUTS

### [WildcardPattern]

## NOTES

TODO: There is another function with the same name in Scripts folder

## RELATED LINKS
