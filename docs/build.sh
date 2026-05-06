#!/usr/bin/env bash
set -euo pipefail

# Multi-pass VitePress build for large formula sites.
# Moves individual .md files in batches to avoid OOM.

cd "$(dirname "$0")"

BROWSE_DIR="browse"
STAGING_DIR=".browse-staging"
DIST_DIR=".vitepress/dist"
FINAL_DIR=".vitepress/dist-final"
MAX_OLD_SPACE="${MAX_OLD_SPACE:-6144}"
BATCH_SIZE="${BATCH_SIZE:-500}"

# Generate all formula pages
echo "=== Generating formula pages ==="
node generate.js

# Save all browse .md files (except index.md) to staging
echo "=== Staging browse pages ==="
rm -rf "$STAGING_DIR" "$FINAL_DIR"
mkdir -p "$STAGING_DIR"

# Move all .md files except index.md, preserving directory structure
find "$BROWSE_DIR" -name "*.md" ! -name "index.md" | while read -r f; do
  relpath="${f#$BROWSE_DIR/}"
  mkdir -p "$STAGING_DIR/$(dirname "$relpath")"
  mv "$f" "$STAGING_DIR/$relpath"
done

echo "=== Pass 0: Main site (guide, licenses, browse/index) ==="
NODE_OPTIONS="--max-old-space-size=$MAX_OLD_SPACE" npx vitepress build
mv "$DIST_DIR" "$FINAL_DIR"
main_pages=$(find "$FINAL_DIR" -name "*.html" | wc -l | tr -d ' ')
echo "Main site built: $main_pages pages"

# Enumerate all staged .md files
mapfile -t all_files < <(find "$STAGING_DIR" -name "*.md" | sort)
total=${#all_files[@]}
num_batches=$(( (total + BATCH_SIZE - 1) / BATCH_SIZE ))
echo "=== $total formula pages in $num_batches batches (batch size: $BATCH_SIZE) ==="

# Build each batch
for ((batch=0; batch<num_batches; batch++)); do
  start=$((batch * BATCH_SIZE))
  end=$((start + BATCH_SIZE))
  if [ "$end" -gt "$total" ]; then end=$total; fi

  batch_num=$((batch + 1))
  batch_count=$((end - start))

  echo ""
  echo "=== Pass $batch_num: $batch_count pages ($((start+1))-$end of $total) ==="

  # Move this batch of files into browse/
  for ((i=start; i<end; i++)); do
    f="${all_files[$i]}"
    relpath="${f#$STAGING_DIR/}"
    mkdir -p "$BROWSE_DIR/$(dirname "$relpath")"
    mv "$f" "$BROWSE_DIR/$relpath"
  done

  NODE_OPTIONS="--max-old-space-size=$MAX_OLD_SPACE" npx vitepress build

  # Copy browse output into final dist
  if [ -d "$DIST_DIR/browse" ]; then
    # Copy all browse subdirectories
    for d in "$DIST_DIR/browse"/*/; do
      [ -d "$d" ] || continue
      dirname=$(basename "$d")
      mkdir -p "$FINAL_DIR/browse/$dirname"
      cp -r "$d" "$FINAL_DIR/browse/$dirname/" 2>/dev/null || true
    done
    # Copy any .html files directly in browse/
    cp "$DIST_DIR/browse/"*.html "$FINAL_DIR/browse/" 2>/dev/null || true
    batch_pages=$(find "$DIST_DIR/browse" -name "*.html" ! -name "index.html" | wc -l | tr -d ' ')
    echo "  Added $batch_pages browse pages"
  fi

  # Move files back to staging
  for ((i=start; i<end; i++)); do
    f="${all_files[$i]}"
    relpath="${f#$STAGING_DIR/}"
    mkdir -p "$(dirname "$f")"
    mv "$BROWSE_DIR/$relpath" "$f" 2>/dev/null || true
  done
  # Clean empty directories
  find "$BROWSE_DIR" -type d -empty -delete 2>/dev/null || true

  rm -rf "$DIST_DIR"
done

# Clean up staging
rm -rf "$STAGING_DIR"

# Final dist
rm -rf "$DIST_DIR"
mv "$FINAL_DIR" "$DIST_DIR"

total_pages=$(find "$DIST_DIR" -name "*.html" | wc -l | tr -d ' ')
echo ""
echo "=== Build complete: $total_pages total HTML pages ==="
