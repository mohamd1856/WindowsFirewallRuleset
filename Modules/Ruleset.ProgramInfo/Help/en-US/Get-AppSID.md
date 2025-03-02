---
external help file: Ruleset.ProgramInfo-help.xml
Module Name: Ruleset.ProgramInfo
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md
schema: 2.0.0
---

# Get-AppSID

## SYNOPSIS

Get store app SID

## SYNTAX

```powershell
Get-AppSID [-PackageFamilyName] <String[]> [<CommonParameters>]
```

## DESCRIPTION

Get SID for single store app if the app exists

## EXAMPLES

### EXAMPLE 1

```powershell
Get-AppSID "Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
```

## PARAMETERS

### -PackageFamilyName

"PackageFamilyName" string

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: FamilyName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string] "PackageFamilyName" string

## OUTPUTS

### [string] store app SID (security identifier)

## NOTES

Big thanks to ljani for this awesome solution, see issue from "related links" section

## RELATED LINKS

[https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md](https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-AppSID.md)

[https://github.com/metablaster/WindowsFirewallRuleset/issues/6](https://github.com/metablaster/WindowsFirewallRuleset/issues/6)
