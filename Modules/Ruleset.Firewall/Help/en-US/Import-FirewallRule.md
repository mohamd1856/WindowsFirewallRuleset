---
external help file: Ruleset.Firewall-help.xml
Module Name: Ruleset.Firewall
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallRule.md
schema: 2.0.0
---

# Import-FirewallRule

## SYNOPSIS

Imports firewall rules from a CSV or JSON file

## SYNTAX

```powershell
Import-FirewallRule [-Domain <String>] -Path <DirectoryInfo> [-FileName <String>] [-JSON] [-Force]
 [<CommonParameters>]
```

## DESCRIPTION

Imports firewall rules exported with Export-FirewallRule, CSV or JSON file.
CSV files have to be separated with semicolons.
Existing rules with same name will not be overwritten by default.

## EXAMPLES

### EXAMPLE 1

```powershell
Import-FirewallRule
```

Imports all firewall rules in the CSV file FirewallRules.csv
If no file is specified, FirewallRules .csv or .json in the current directory is searched.

### EXAMPLE 2

```powershell
Import-FirewallRule -FileName WmiRules -JSON
```

Imports all firewall rules from the JSON file WmiRules

## PARAMETERS

### -Domain

Computer name onto which to import rules, default is local GPO.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases: ComputerName, CN

Required: False
Position: Named
Default value: [System.Environment]::MachineName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path

Path to directory where the exported rules file is located.
Wildcard characters are supported.

```yaml
Type: System.IO.DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -FileName

Export file file containing firewall rules

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: FirewallRules
Accept pipeline input: False
Accept wildcard characters: False
```

### -JSON

Input from JSON instead of CSV format

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

### -Force

If specified, overwrites existing rules with same name as rules being imported

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

### None. You cannot pipe objects to Import-FirewallRule

## OUTPUTS

### None. Import-FirewallRule does not generate any output

## NOTES

Author: Markus Scholtes
Version: 1.02
Build date: 2020/02/15

The Following modifications by metablaster August 2020:

1. Applied formatting and code style according to project rules
2. Added parameter to target specific policy store
3. Separated functions into their own scope
4. Added function to decode string into multi line
5. Added parameter to let specify directory
6. Added more output streams for debug, verbose and info
7. Changed minor flow and logic of execution
8. Make output formatted and colored
9. Added progress bar

December 2020:

1. Rename parameters according to standard name convention
2. Support resolving path wildcard pattern

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallRule.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Firewall/Help/en-US/Import-FirewallRule.md)

[https://github.com/MScholtes/Firewall-Manager](https://github.com/MScholtes/Firewall-Manager)
