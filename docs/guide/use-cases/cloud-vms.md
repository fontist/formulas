---
title: Cloud VMs
description: Using Fontist formulas on cloud virtual machines
---

# Cloud VMs

Fontist works on cloud VMs from AWS, Azure, GCP, and other providers.

## Platform Considerations

### Linux VMs

Most cloud VMs run Linux - use open source or freely distributable fonts:

```bash
# SSH into VM
gem install fontist
fontist install "open_sans" "roboto"
```

### Windows VMs (Azure)

Windows VMs on Azure can use Microsoft fonts:

1. **Microsoft Office fonts** - If MS Office is installed
2. **Microsoft Web Fonts** - Freely distributable (Andale, Arial, etc.)
3. **Open source fonts** - Via Fontist

### macOS VMs (MacStadium, GitHub Actions)

macOS VMs can use Apple system fonts:

- **Available**: All macOS system fonts
- **Restriction**: Only on Apple-branded hardware
- **GitHub Actions**: Available on `macos-latest` runners

## AWS

### EC2 User Data

```bash
#!/bin/bash
# Install Ruby
yum install -y ruby ruby-devel

# Install Fontist
gem install fontist

# Install fonts
fontist install "open_sans"
```

### ECS Task Definition

```json
{
  "containerDefinitions": [{
    "name": "app",
    "image": "myapp:latest",
    "command": ["fontist", "install", "open_sans"]
  }]
}
```

## Azure

### VM Extension

```json
{
  "type": "CustomScript",
  "properties": {
    "commandToExecute": "gem install fontist && fontist install open_sans"
  }
}
```

### Windows on Azure

For Windows VMs with MS Office:

```powershell
# MS Office fonts are already available
# Install additional fonts via Fontist
gem install fontist
fontist install "google/roboto"
```

## Google Cloud

### Compute Engine Startup Script

```bash
#!/bin/bash
apt-get update
apt-get install -y ruby
gem install fontist
fontist install "open_sans"
```

### Cloud Run

Fonts must be in the container image:

```dockerfile
FROM ruby:3.2-slim
RUN gem install fontist
RUN fontist install "open_sans"
```

## GitHub Hosted Runners

### Ubuntu Runner

```yaml
runs-on: ubuntu-latest
steps:
  - run: gem install fontist
  - run: fontist install "open_sans"
```

### macOS Runner

```yaml
runs-on: macos-latest
steps:
  # Apple fonts are pre-installed
  - run: fontist install "open_sans"  # Additional fonts
```

### Windows Runner

```yaml
runs-on: windows-latest
steps:
  - run: gem install fontist
  - run: fontist install "open_sans"
```

## License Compliance

| Platform | Allowed Fonts |
|----------|--------------|
| Linux VMs | Open source, freely distributable |
| Windows VMs (with Office) | MS Office fonts, open source |
| macOS VMs | Apple fonts, open source |
| GitHub Actions macOS | Apple fonts, open source |

::: warning
Apple-only fonts are only legal on Apple-branded hardware. GitHub Actions and MacStadium provide legitimate macOS VMs.
:::

## See Also

- [CI/CD & Servers](/guide/use-cases/server-side)
- [Docker & Containers](/guide/use-cases/containerized)
- [Apple-only License](/licenses/apple-only)
