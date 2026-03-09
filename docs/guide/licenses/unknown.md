# License Not Specified

[![License: Check Source](https://img.shields.io/badge/License-Check%20Source-17a2b8)](#) [![Category: Unknown](https://img.shields.io/badge/Category-Unknown-17a2b8)]

**SPDX Identifier:** N/A

## Quick Summary

This formula does not contain license information in its YAML file. **This does not mean the font is proprietary!** You must check the font's source to determine the license.

## What This Means

When a formula shows "License Not Specified":

1. **The formula lacks license metadata** - The YAML file doesn't include license info
2. **The font may still be free** - Many free fonts have incomplete formulas
3. **You must verify** - Check the homepage or font file for license info
4. **Don't assume** - Neither assume it's free nor proprietary

## How to Find License Info

### Step 1: Check the Homepage

Every formula includes a homepage link:
```
fontist info "[formula-name]"
```
Visit the homepage and look for:
- License page
- FAQ
- Download terms
- README file

### Step 2: Check the Font File

Font files contain metadata:

```bash
# Using otfinfo (install via lcdf-typetools)
otfinfo --info Font.ttf | grep -i license

# Using fonttools
pip install fonttools
ttx -t name Font.ttf | grep -i license
```

### Step 3: Check Font Properties

On Windows:
- Right-click font → Properties → Details

On macOS:
- Open in Font Book → Font Info

### Step 4: Contact the Author

If license info is not found:
- Email the foundry
- Check their website
- Look for GitHub repository

## Common Scenarios

### "I can't find any license"

This may indicate:
- Public domain (rare but possible)
- All rights reserved (proprietary)
- Forgotten to include license

**Recommendation:** Contact the author or find an alternative.

### "The website says it's free"

"Free" doesn't specify terms:
- Free for personal use?
- Free for commercial use?
- Free to redistribute?
- Free to modify?

**Recommendation:** Get written clarification.

### "It's on a free font site"

Download sites may not have accurate info:
- License may have changed
- Site may be unauthorized
- Terms may be outdated

**Recommendation:** Find the original source.

## Reporting Missing License Info

If you determine the license for a font with missing info:

1. Open an issue: https://github.com/fontist/formulas/issues
2. Include:
   - Formula name
   - License type
   - Source/URL for license info

Help us improve the formula database!

## See Also

- [License Overview](./) - All license types
- [Freely Usable](./free-use) - Fonts with broad permissions
- [Freeware](./freeware) - Free with restrictions
