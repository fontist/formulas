# Microsoft Software License

[![License: MS Software](https://img.shields.io/badge/License-MS%20Software-8b5cf6)](#) [![Category: Bundled Software](https://img.shields.io/badge/Category-Bundled%20Software-8b5cf6)]

**SPDX Identifier:** Not on SPDX

## Quick Summary

Fonts bundled with Microsoft Office or Windows are licensed under Microsoft's Software License. They can only be used on licensed Microsoft software installations.

## Permissions Overview

### ✅ Allows For

| Context | Permission | Notes |
|---------|------------|-------|
| Desktop (Windows) | ✅ On licensed Windows | |
| Desktop (MS Office) | ✅ With MS Office license | |
| Commercial (Static) | ✅ On licensed system | |
| Application embedding | ✅ Some fonts | Check specific EULA |

### ❌ Disallows For

| Permission | Notes |
|------------|-------|
| Redistribution | Cannot distribute font files |
| Modification | Cannot edit fonts |
| Web embedding | Generally not allowed |
| Server/CI | Requires proper licensing |
| Format Conversion | Not allowed |

## Usage Guidance

To legally use Microsoft-bundled fonts:

1. **Install Microsoft Office** - On your workstation
2. **Use licensed Windows** - System fonts are included
3. **Check embedding rights** - Some fonts allow document embedding
4. **Do not extract fonts** - Don't copy fonts from Office installations

## Embedding Rights

Microsoft fonts may have different embedding levels:

| Level | Description |
|-------|-------------|
| Installable | Can install and embed freely |
| Editable | Can embed in editable documents |
| Print/Preview | Can embed for printing only |
| Restricted | Cannot embed |

Check font properties to determine embedding rights.

## See Also

- [Microsoft Font Licensing](https://docs.microsoft.com/en-us/typography/fonts/)
- [Microsoft Software License Terms](https://www.microsoft.com/useterms/)
