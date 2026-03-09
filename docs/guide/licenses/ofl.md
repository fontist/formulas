# SIL Open Font License 1.1

[![License: OFL 1.1](https://img.shields.io/badge/License-OFL%201.1-28a745)](https://spdx.org/licenses/OFL-1.1.html) [![Category: Open Source](https://img.shields.io/badge/Category-Open%20Source-28a745)]

**SPDX Identifier:** `OFL-1.1`
**SPDX Page:** https://spdx.org/licenses/OFL-1.1.html

## Quick Summary

The SIL Open Font License (OFL) is the most permissive and popular license specifically designed for fonts. It allows free use, modification, and redistribution with minimal restrictions.

## Permissions Overview

### ✅ Allows For

| Context | Permission | Notes |
|---------|------------|-------|
| Academic | ✅ Full | Use in research, education, thesis |
| Non-commercial | ✅ Full | Personal projects, hobbies |
| Commercial (Static) | ✅ Full | PDFs, images, printed materials |
| Commercial (Server) | ✅ Full | CI/CD, automated document generation |
| Web (Hosting) | ✅ Full | Self-host WOFF/WOFF2/SVG |
| Web (Subsetting) | ✅ Full | Create subsets for performance |
| Desktop (Personal) | ✅ Full | Install on personal machines |
| Desktop (Commercial) | ✅ Full | Install for commercial work |
| Server/CI | ✅ Full | Install on servers, cloud |
| Redistribution (Bundled) | ✅ Full | Include in npm/gem/any package |
| Redistribution (Standalone) | ✅ Full | Distribute font files separately |
| Modification | ✅ With conditions | Must rename using Reserved Font Name rules |
| Subsetting | ✅ Full | Create subset fonts |
| Format Conversion | ✅ Full | TTF ↔ WOFF ↔ WOFF2 |
| Commercial Documents | ✅ Full | Any commercial use |

### ⚠️ Conditional

| Permission | Condition |
|------------|-----------|
| Redistribution | Must include OFL license text and copyright notice |
| Modification | Must not use Reserved Font Name for modified versions |
| Bundling | Should include license file in package |

### ❌ Disallows For

| Permission | Notes |
|------------|-------|
| Standalone Sale | Cannot sell the font files by themselves |
| Reserved Name Use | Cannot use Reserved Font Name for modified versions |

## Usage Examples

### What You CAN Do

- Use the font on your personal website
- Include the font in your npm package (with license file)
- Create a modified version with a new name
- Use in a commercial logo design
- Generate PDFs on a CI server using the font
- Subset the font for faster web loading
- Convert to WOFF2 for web hosting
- Use in a paid design project
- Bundle with your software application

### What You CANNOT Do

- Sell the font files alone as a product
- Modify the font and keep the same Reserved Font Name
- Remove the license or copyright notice

## Technical Details

### Format Conversion

```bash
# Convert TTF to WOFF2
fonttools ttLib.woff2 compress Font.ttf

# Create subset for web
pyftsubset Font.ttf --output-file=Font-subset.woff2 \
  --flavor=woff2 \
  --layout-features='*' \
  --glyphs=*/.notdef
```

### Required Files When Bundling

When redistributing OFL fonts, include:
1. The font file(s)
2. The OFL license text (typically `OFL.txt`)
3. Any copyright notice files

## Full License Text

<details>
<summary>View Full SIL Open Font License 1.1</summary>

```
SIL OPEN FONT LICENSE

Version 1.1 - 26 February 2007

PREAMBLE

The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font creation
efforts of academic and linguistic communities, and to provide a free and
open framework in which fonts may be shared and improved in partnership
with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply
to any document created using the fonts or their derivatives.

DEFINITIONS

"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software components
as distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software
to a new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS

Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed, modify,
redistribute, and sell modified and unmodified copies of the Font
Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components,
in Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the corresponding
Copyright Holder. This restriction only applies to the primary font name
as presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created
using the Font Software or any of its derivatives.

TERMINATION

This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER

THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
```

</details>

## See Also

- [SIL OFL FAQ](https://scripts.sil.org/OFL-FAQ_web)
- [SIL OFL Official Page](https://scripts.sil.org/OFL)
- [Google Fonts OFL Guide](https://developers.google.com/fonts/docs/legal_others)
