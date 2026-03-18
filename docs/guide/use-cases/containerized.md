---
title: Docker & Containers
description: Using Fontist formulas in Docker containers and Kubernetes
---

# Docker & Containers

Fontist works well in containerized environments for reproducible font management.

## Basic Docker Setup

### Simple Dockerfile

```dockerfile
FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Install Fontist
RUN gem install fontist

# Install fonts
RUN fontist install "open_sans" "roboto"

# Your application
COPY . /app
WORKDIR /app
CMD ["ruby", "app.rb"]
```

### With Fontfile

Create a `Fontfile`:

```
"open_sans"
"roboto"
"source_sans_pro"
```

Dockerfile:

```dockerfile
FROM ruby:3.2-slim

RUN gem install fontist
COPY Fontfile .
RUN xargs -a Fontfile fontist install

COPY . /app
WORKDIR /app
CMD ["ruby", "app.rb"]
```

## Multi-stage Builds

For smaller images:

```dockerfile
# Build stage - install fonts
FROM ruby:3.2-slim AS builder

RUN gem install fontist
COPY Fontfile .
RUN fontist install "open_sans"

# Runtime stage - minimal image
FROM debian:bookworm-slim

# Copy only fonts, not Fontist
COPY --from=builder /root/.fontist/fonts /usr/share/fonts/fontist

# Refresh font cache
RUN fc-cache -f -v

CMD ["your-app"]
```

## Alpine Linux

```dockerfile
FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache fontconfig freetype

# Install Fontist
RUN gem install fontist

# Install fonts
RUN fontist install "open_sans"

CMD ["ruby", "app.rb"]
```

## Kubernetes

### ConfigMap for Fonts

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: font-config
data:
  Fontfile: |
    "open_sans"
    "roboto"
```

### Init Container

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      initContainers:
      - name: install-fonts
        image: ruby:3.2-slim
        command: ["/bin/sh", "-c"]
        args:
          - |
            gem install fontist
            fontist install "open_sans"
        volumeMounts:
        - name: fonts
          mountPath: /root/.fontist
      containers:
      - name: app
        image: myapp:latest
        volumeMounts:
        - name: fonts
          mountPath: /root/.fontist
      volumes:
      - name: fonts
        emptyDir: {}
```

## Docker Compose

```yaml
version: '3.8'
services:
  app:
    build: .
    volumes:
      - fonts:/root/.fontist

volumes:
  fonts:
```

## Best Practices

### 1. Use Specific Font Versions

```bash
fontist install "open_sans" --version "1.0"
```

### 2. Minimize Image Size

- Use multi-stage builds
- Only install needed fonts
- Use `--no-install-recommends`

### 3. Cache Fonts

Mount `~/.fontist` as a volume to avoid reinstalling.

## See Also

- [CI/CD & Servers](/guide/use-cases/server-side)
- [PDF Generation](/guide/use-cases/pdf-generation)
