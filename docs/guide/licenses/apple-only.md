# Apple-only License

[![License: Apple-only](https://img.shields.io/badge/License-Apple--only-f0ad4e)](#) [![Category: Platform Restricted](https://img.shields.io/badge/Category-Platform%20Restricted-f0ad4e)]

**SPDX Identifier:** Not on SPDX (Proprietary)

## Quick Summary

macOS system fonts are licensed by Apple for use on Apple-branded systems only. These fonts are not open source and cannot be freely redistributed or used on non-Apple platforms.

## Permissions Overview

### ✅ Allows For

| Context | Permission | Notes |
|---------|------------|-------|
| Academic | ✅ On Apple hardware | Use in research on Mac computers |
| Non-commercial | ✅ On Apple hardware | Personal projects on Mac |
| Commercial (Static) | ✅ On Apple hardware | Create PDFs/images on Mac for distribution |
| Commercial (Server) | ✅ On macOS servers | Including cloud macOS (GitHub runners, MacStadium, AWS EC2 Mac) |
| Desktop (Personal) | ✅ On Mac | Personal Mac computers |
| Desktop (Commercial) | ✅ On Mac | Commercial work on Mac computers |
| Server/CI | ✅ On macOS | GitHub Actions macOS runners, MacStadium, etc. |
| Cloud Platform | ✅ macOS cloud | AWS EC2 Mac, MacStadium, MacinCloud |

### ❌ Disallows For

| Permission | Notes |
|------------|-------|
| Desktop (Non-Apple) | ❌ Cannot install on Windows, Linux, Hackintosh |
| Web (Hosting) | ❌ Cannot use @font-face for non-Apple clients |
| Web (Subsetting) | ❌ Cannot subset for web distribution |
| Redistribution (Standalone) | ❌ Cannot distribute font files |
| Redistribution (Bundled) | ❌ Cannot include in npm/gem packages |
| Modification | ❌ Cannot edit font files |
| Resale | ❌ Cannot sell font files |
| Format Conversion | ❌ Cannot convert to other formats |

## Usage Examples

### What You CAN Do

- Use fonts on your MacBook for designing a commercial logo
- Install fonts on a Mac mini server for CI/CD document generation
- Use fonts on GitHub Actions macOS runners for PDF generation
- Use fonts on MacStadium cloud Macs for automated builds
- Use fonts on AWS EC2 Mac instances
- Create PDFs on a Mac and distribute them to anyone
- Use fonts in presentations created on a Mac

### What You CANNOT Do

- Install fonts on a Windows PC for design work
- Embed fonts in a website that non-Apple users will view
- Include font files in a npm/gem package
- Modify the font and redistribute it
- Convert fonts to WOFF for web hosting
- Use on Linux-based CI systems
- Distribute font files to others

## Cloud macOS Usage

Apple's license permits use on Apple-branded systems, which includes authorized cloud macOS services:

| Service | Permitted? |
|---------|------------|
| GitHub Actions (macOS runners) | ✅ Yes |
| MacStadium | ✅ Yes |
| AWS EC2 Mac | ✅ Yes |
| MacinCloud | ✅ Yes |
| Any authorized Apple hardware in data center | ✅ Yes |

## Key License Excerpts

From Apple's Font License:

> "The Apple Software is licensed, not sold, to you by Apple Inc. ("Apple") for use only on Apple-branded systems..."

> "Subject to the terms and conditions of this License... you are granted a limited, non-exclusive license to install, use and run one (1) copy of the Apple Software on a single Apple-branded computer at any one time."

## Full License Text

<details>
<summary>View Full Apple Font License</summary>

```
APPLE FONT LICENSE

IMPORTANT: BY DOWNLOADING, INSTALLING OR USING THE APPLE FONT
SOFTWARE ("APPLE FONT"), YOU ARE AGREEING TO BE BOUND BY THE
TERMS OF THIS LICENSE AGREEMENT. IF YOU DO NOT AGREE TO THE
TERMS OF THIS LICENSE, DO NOT DOWNLOAD, INSTALL OR USE THE
APPLE FONT.

1. General. The Apple Font is licensed, not sold, to you by
Apple Inc. ("Apple") for use only under the terms of this
License Agreement. Apple and its licensors retain ownership
of the Apple Font and reserve all rights not expressly
granted to you.

2. Permitted License Uses and Restrictions. Subject to the
terms of this License, you are granted a limited, non-exclusive
license to install and use the Apple Font on Apple-branded
systems only. You may not embed the Apple Font in any documents
for delivery to third parties, except that you may embed the
Apple Font in a PDF document solely for printing and viewing
purposes.

3. Transfer. You may not rent, lease, lend, redistribute or
sublicense the Apple Font.

4. Termination. This License is effective until terminated.
Your rights under this License will terminate automatically
without notice from Apple if you fail to comply with any of
its terms.

5. Disclaimer of Warranty. THE APPLE FONT IS PROVIDED "AS IS"
AND WITHOUT WARRANTY OF ANY KIND. APPLE AND ITS LICENSORS
DISCLAIM ALL WARRANTIES AND CONDITIONS, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES AND
CONDITIONS OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT.

6. Limitation of Liability. IN NO EVENT SHALL APPLE OR ITS
LICENSORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THE APPLE FONT, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.
```

</details>

## See Also

- [Apple Software License Agreement](https://www.apple.com/legal/sla/)
- [Apple Fonts](https://developer.apple.com/fonts/)
