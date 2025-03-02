---
external help file: Ruleset.Test-help.xml
Module Name: Ruleset.Test
online version: https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.Test/Help/en-US/Test-MarkdownLink.md
schema: 2.0.0
---

# Test-MarkdownLink

## SYNOPSIS

Test links in markdown files

## SYNTAX

### Path (Default)

```powershell
Test-MarkdownLink [-Path] <String[]> [-Recurse] [-TimeoutSec <Int32>] [-MaximumRetryCount <Int32>]
 [-RetryIntervalSec <Int32>] [-MaximumRedirection <Int32>] [-SslProtocol <String>] [-NoProxy]
 [-Include <String>] [-Exclude <String>] [-LinkType <String>] [-Unique] [-Depth <UInt32>] [-Log]
 [<CommonParameters>]
```

### Literal

```powershell
Test-MarkdownLink -LiteralPath <String[]> [-Recurse] [-TimeoutSec <Int32>] [-MaximumRetryCount <Int32>]
 [-RetryIntervalSec <Int32>] [-MaximumRedirection <Int32>] [-SslProtocol <String>] [-NoProxy]
 [-Include <String>] [-Exclude <String>] [-LinkType <String>] [-Unique] [-Depth <UInt32>] [-Log]
 [<CommonParameters>]
```

## DESCRIPTION

Test each link in one or multiple markdown files and report if any link is invalid.
You can "brute force" test links or test only unique ones.
Links to be tested can be excluded or included by using wildcard pattern.
Test can be customized for various TLS protocols, query timeouts and retry attempts.
The links to be tested can be reference links, inline links or both.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-MarkdownLink -Path C:\GitHub\MyProject -Recurse
```

### EXAMPLE 2

```powershell
Test-MarkdownLink -Path C:\GitHub\MyProject -SslProtocol Tls -NoProxy
```

### EXAMPLE 3

```powershell
Test-MarkdownLink .\MyProject\MarkdownFile.md -LinkType "Reference" -Include *microsoft.com*
```

## PARAMETERS

### -Path

Specifies a path to one or more locations containing target markdown files.
Wildcard characters are supported.

```yaml
Type: System.String[]
Parameter Sets: Path
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -LiteralPath

Specifies a path to one or more locations containing target markdown files.
The value of LiteralPath is used exactly as it's typed.
No characters are interpreted as wildcards.

```yaml
Type: System.String[]
Parameter Sets: Literal
Aliases: LP

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse

If specified, recurse in to the path specified by Path parameter

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

### -TimeoutSec

Specifies (per link) how long the request can be pending before it times out.
A value, 0, specifies an indefinite time-out.
A Domain Name System (DNS) query can take up to 15 seconds to return or time out.

If your request contains a host name that requires resolution, and you set TimeoutSec to a value
greater than zero, but less than 15 seconds, it can take 15 seconds or more before the request
times out.
The default value is 20 seconds.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumRetryCount

Specifies (per link) how many times PowerShell retries a connection when a failure code between 400
and 599, inclusive or 304 is received.
This parameter is valid for PowerShell Core edition only.
The default value is defined in $PSSessionOption preference variable

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PSSessionOption.MaxConnectionRetryCount
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryIntervalSec

Specifies the interval between retries for the connection when a failure code between 400 and
599, inclusive or 304 is received
This parameter is valid for PowerShell Core edition only.
The default value is 3 seconds

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumRedirection

Specifies how many times PowerShell redirects a connection to an alternate Uniform Resource
Identifier (URI) before the connection fails.
A value of 0 (zero) prevents all redirection.
The default value is 5

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -SslProtocol

Sets the SSL/TLS protocols that are permissible for the web request.
This feature was added in PowerShell 6.0.0 and support for Tls13 was added in PowerShell 7.1.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Default
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoProxy

Indicates the test shouldn't use a proxy to reach the destination.
This feature was added in PowerShell 6.0.0.

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

### -Include

Specifies an URL wildcard pattern that this function includes in the operation.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
```

### -Exclude

Specifies an URL wildcard pattern that this function excludes from operation.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -LinkType

Specifies the type of links to check, acceptable values are:

-Inline ex.
\[label\](URL)
-Reference ex.
\[label\]: URL
-Any process both inline and reference links

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Any
Accept pipeline input: False
Accept wildcard characters: False
```

### -Unique

If specified, only unique links are tested reducing the amount of time needed for bulk link test operation

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

### -Depth

The Depth parameter determines the number of subdirectory levels that are included in the recursion.
For example, Depth 2 includes the Path parameter's directory, first level of subdirectories, and
second level of subdirectories.

```yaml
Type: System.UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Log

If specified, invalid links are logged.
Log file can be found in Logs\MarkdownLinkTest_DATE.log

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

### None. You cannot pipe objects to Test-MarkdownLink

## OUTPUTS

### None. Test-MarkdownLink does not generate any output

## NOTES

WebSslProtocol enum does not list Tls13
TODO: Implement pipeline support
TODO: Implement testing links to repository

## RELATED LINKS
