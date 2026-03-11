---
title: CI/CD & Servers
description: Using Fontist formulas in continuous integration and server environments
---

# CI/CD & Servers

Fontist is designed for reproducible font installation in automated environments.

## GitHub Actions

### Official Action

```yaml
- name: Install fonts
  uses: fontist/setup-fontist@v2
  with:
    fonts: Open Sans, Roboto, Source Sans Pro
```

### Manual Installation

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'

      - name: Install Fontist
        run: gem install fontist

      - name: Install fonts
        run: fontist install "open_sans" "roboto"

      - name: Generate documents
        run: pandoc input.md -o output.pdf
```

### Caching

```yaml
- name: Cache fonts
  uses: actions/cache@v4
  with:
    path: ~/.fontist
    key: fonts-${{ hashFiles('Fontfile') }}
```

## GitLab CI

```yaml
generate-docs:
  image: ruby:3.2
  cache:
    paths:
      - ~/.fontist/
  script:
    - gem install fontist
    - fontist install "open_sans"
    - pandoc input.md -o output.pdf
  artifacts:
    paths:
      - output.pdf
```

## Docker

### Dockerfile

```dockerfile
FROM ruby:3.2

# Install Fontist
RUN gem install fontist

# Install fonts during build
RUN fontist install "open_sans" "roboto"

# Or copy a Fontfile and install
COPY Fontfile .
RUN xargs -a Fontfile fontist install
```

### Multi-stage Build

```dockerfile
# Build stage
FROM ruby:3.2 AS builder
RUN gem install fontist
COPY Fontfile .
RUN xargs -a Fontfile fontist install

# Runtime stage
FROM debian:bookworm-slim
COPY --from=builder /root/.fontist /root/.fontist
```

## Server Deployment

### systemd Service

```ini
[Unit]
Description=Document Generator

[Service]
ExecStartPre=/usr/bin/fontist install "open_sans"
ExecStart=/usr/bin/ruby /app/server.rb
```

### Environment Variables

```bash
# Custom font directory
export FONTIST_PATH=/var/lib/fonts
fontist install "open_sans"
```

## License Considerations for Servers

| License Type | Server Use | Notes |
|--------------|------------|-------|
| OFL 1.1 | ✅ Allowed | Best choice for CI/CD |
| Apache/MIT | ✅ Allowed | Fully permissive |
| Platform Restricted | ⚠️ Check | macOS fonts only on macOS runners |
| Bundled Software | ❌ Usually no | Cannot extract from software |

### Platform-Specific Runners

- **macOS runners**: Can use Apple-only fonts
- **Windows runners**: Can use Microsoft fonts
- **Linux runners**: Use open source or freely distributable fonts

## See Also

- [Docker & Containers](/guide/use-cases/containerized)
- [Cloud VMs](/guide/use-cases/cloud-vms)
- [GitHub Actions Integration](https://github.com/fontist/setup-fontist)
