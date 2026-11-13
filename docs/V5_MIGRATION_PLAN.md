# Formula Schema v5 Migration Plan

## Overview

This document outlines the migration from Formula Schema v4 to v5, which introduces
multi-format font support and variable font metadata.

## Schema Changes

### v4 Schema (Current)

```yaml
name: Roboto
description: Roboto
homepage: Google.com
resources:
  Roboto:
    source: google
    family: Roboto
    files:
    - https://fonts.gstatic.com/s/roboto/v30/KFOkCnqEu92Fr1MmgWxPKTM1K9nz.ttf
fonts:
- name: Roboto
  styles:
  - family_name: Roboto
    type: Bold
    font: KFOlCnqEu92Fr1MmWUlvAx05IsDqlA.ttf
```

### v5 Schema (Target)

```yaml
name: Roboto
schema_version: 5
description: Roboto font family
homepage: https://fonts.google.com/specimen/Roboto
resources:
  ttf_static:
    source: google
    format: ttf
    urls:
    - https://fonts.gstatic.com/s/roboto/v30/KFOkCnqEu92Fr1MmgWxPKTM1K9nz.ttf
    files:
    - KFOkCnqEu92Fr1MmgWxPKTM1K9nz.ttf
  woff2_static:
    source: google
    format: woff2
    urls:
    - https://fonts.gstatic.com/s/roboto/v30/KFOkCnqEu92Fr1MmgWxPKTM1K9nz.woff2
    files:
    - KFOkCnqEu92Fr1MmgWxPKTM1K9nz.woff2
fonts:
- name: Roboto
  styles:
  - family_name: Roboto
    type: Bold
    font: KFOlCnqEu92Fr1MmWUlvAx05IsDqlA.ttf
    formats: ["ttf", "woff2"]
    source_resource: ttf_static
import_source:
  type: google
  commit_id: abc123...
  api_version: v1
  last_modified: "2024-01-15T10:30:00Z"
```

## Key Differences

| Feature | v4 | v5 |
|---------|----|----|
| Schema version | Implicit (4) | Explicit `schema_version: 5` |
| Font formats | TTF only | TTF, WOFF2, Variable |
| Resource naming | Single resource | Multiple by format (ttf_static, woff2_static, woff2_variable) |
| Format metadata | None | `format` attribute on resources |
| Variable font support | No | `variable_axes` attribute |
| Style formats | None | `formats` array on styles |
| Import provenance | Limited | Full `import_source` with commit_id |

## Migration Strategy

### Option 1: Re-import (Recommended)

Re-import all fonts using the updated importers with `--schema-version=5`:

```bash
# Google Fonts (requires API key and google/fonts checkout)
fontist import google \
  --source-path=/path/to/google/fonts \
  --schema-version=5 \
  --output-path=./Formulas/google \
  --force

# macOS Fonts (requires catalog file)
fontist import macos \
  --plist=com_apple_MobileAsset_Font8.xml \
  --schema-version=5 \
  --output-path=./Formulas/macos \
  --force

# SIL Fonts
fontist import sil \
  --schema-version=5 \
  --output-path=./Formulas/sil \
  --force
```

### Option 2: Migration Script

For manually created formulas that cannot be re-imported, use the migration tool:

```bash
fontist migrate-formulas ./Formulas ./Formulas --dry-run
```

## Formula Sets to Migrate

| Location | Count | Source | Migration Method |
|----------|-------|--------|------------------|
| `Formulas/google/` | ~1662 | Google API | Re-import |
| `Formulas/macos/` | ~323 | Apple catalog | Re-import |
| `Formulas/sil/` | ~69 | SIL website | Re-import |
| `Formulas/*.yml` | varies | Manual | Migration script |
| `Formulas/private/` | varies | Manual | Migration script |

## Benefits of v5 Schema

1. **Format Selection**: Users can request specific formats (WOFF2 for web)
2. **Variable Font Support**: Full variable axes metadata for filtering
3. **Better Provenance**: `import_source` tracks exact commit/API version
4. **Future-Proof**: Extensible schema for additional formats (OTF, TTC)
5. **Backward Compatible**: v4 formulas continue to work

## Testing

### Unit Tests

All v5-related classes have comprehensive specs:
- `spec/fontist/format_spec_spec.rb`
- `spec/fontist/format_matcher_spec.rb`
- `spec/fontist/font_finder_spec.rb`

### Integration Tests

Test v5 formula installation:
```bash
# Test format selection
fontist install "Roboto" --format woff2

# Test variable font filtering
fontist find --axes wght,wdth

# Test manifest with format
cat <<EOF > test_manifest.yml
Roboto:
  styles: [Regular]
  format: woff2
EOF
fontist manifest install test_manifest.yml
```

## Rollout Plan

1. **Phase 1**: Create v5 branch, test imports
2. **Phase 2**: Re-import Google, macOS, SIL formulas
3. **Phase 3**: Migrate remaining formulas
4. **Phase 4**: Update CI to validate v5 formulas
5. **Phase 5**: Merge v5 to main (or keep as separate feed)

## Backward Compatibility

- v4 formulas are NOT modified
- Fontist library supports both v4 and v5
- `schema_version` defaults to 4 if not present
- Format options ignored for v4 formulas
