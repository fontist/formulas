---
title: PDF Generation
description: Using Fontist formulas for PDF generation in various programming languages
---

# PDF Generation

Fontist provides fonts for PDF generation in Ruby, Python, JavaScript, and other languages.

## Ruby

### Prawn

```ruby
require 'prawn'

# Install fonts first: fontist install "dejavu"
font_path = File.expand_path('~/.fontist/fonts/DejaVuSans.ttf')

Prawn::Document.generate('document.pdf') do
  font font_path
  text "Hello, World!"
end
```

### Grover (Headless Chrome)

```ruby
require 'grover'

# Fonts available to the system will be used
Grover.new('<h1>Hello</h1>').to_pdf
```

## Python

### ReportLab

```python
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# Install: fontist install "liberation"
pdfmetrics.registerFont(TTFont('Liberation', '/home/user/.fontist/fonts/LiberationSerif-Regular.ttf'))

c = canvas.Canvas('document.pdf')
c.setFont('Liberation', 12)
c.drawString(100, 750, "Hello, World!")
c.save()
```

### WeasyPrint

```python
from weasyprint import HTML

# CSS can reference installed fonts
HTML(string='<p style="font-family: DejaVu Sans">Hello</p>').write_pdf('output.pdf')
```

## Node.js

### PDFKit

```javascript
const PDFDocument = require('pdfkit');

const doc = new PDFDocument();
doc.font('/home/user/.fontist/fonts/DejaVuSans.ttf')
   .text('Hello, World!')
   .end();
```

### Puppeteer/Playwright

```javascript
const puppeteer = require('puppeteer');

// Fonts installed via fontist are available
const browser = await puppeteer.launch();
const page = await browser.newPage();
await page.setContent('<h1>Hello</h1>');
await page.pdf({ path: 'output.pdf' });
```

## wkhtmltopdf

```bash
# Install fonts
fontist install "liberation"

# Generate PDF
wkhtmltopdf --encoding utf-8 input.html output.pdf
```

## Prince XML

```bash
fontist install "dejavu"
prince input.html -o output.pdf
```

## Best Practices

### 1. Embed Fonts in PDF

Always embed fonts for consistent rendering:

```ruby
# Prawn - fonts are embedded by default
font '/path/to/font.ttf'
```

### 2. Use Unicode Fonts

For international text, use fonts with broad character coverage:

```bash
fontist install "noto" "dejavu"
```

### 3. Check Embedding Permissions

Most open source licenses allow embedding. Check the license page for details.

## See Also

- [Document Generation](/guide/use-cases/document-generation)
- [CI/CD & Servers](/guide/use-cases/server-side)
