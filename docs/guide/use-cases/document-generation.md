---
title: Document Generation
description: Using Fontist formulas for automated document generation
---

# Document Generation

Fontist enables reproducible document generation with tools like Pandoc, Asciidoctor, and LaTeX.

## Common Tools

### Pandoc

```bash
# Install fonts for PDF generation
fontist install "liberation" "dejavu"

# Generate PDF with custom fonts
pandoc document.md -o document.pdf \
  --pdf-engine=xelatex \
  -V mainfont="Liberation Serif"
```

### Asciidoctor PDF

```ruby
# theme.yml
font:
  catalog:
    Roboto: /path/to/fontist/fonts/Roboto-Regular.ttf
```

```bash
asciidoctor-pdf document.adoc -a pdf-theme=theme.yml
```

### LaTeX / XeLaTeX

```latex
\documentclass{article}
\usepackage{fontspec}
\setmainfont{Liberation Serif}
```

```bash
# Install fonts first
fontist install "liberation"

# Compile with XeLaTeX
xelatex document.tex
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Install Fontist
  run: gem install fontist

- name: Install fonts
  run: fontist install "liberation" "dejavu"

- name: Generate PDF
  run: pandoc document.md -o document.pdf
```

### GitLab CI

```yaml
generate-docs:
  script:
    - gem install fontist
    - fontist install "liberation"
    - pandoc document.md -o document.pdf
  artifacts:
    paths:
      - document.pdf
```

## Best Practices

### 1. Use Open Source Fonts

For CI/CD, prefer OFL-licensed fonts:

```bash
fontist install "google/roboto" "google/opensans"
```

### 2. Document Font Dependencies

Create a `Fontfile`:

```
"roboto"
"source_sans_pro"
"dejavu"
```

Install all at once:

```bash
xargs -a Fontfile fontist install
```

### 3. Cache Font Installations

In CI, cache `~/.fontist/` between runs.

## License Considerations

| Use Case | Check Permission |
|----------|-----------------|
| Server-side rendering | "Server/CI" |
| PDF embedding | "Commercial (Static)" |
| Document distribution | "Redistribution" |

## See Also

- [CI/CD & Servers](/guide/use-cases/server-side)
- [PDF Generation](/guide/use-cases/pdf-generation)
