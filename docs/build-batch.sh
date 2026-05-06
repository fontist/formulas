#!/usr/bin/env bash
set -euo pipefail

# Build a range of formula pages in sequential batches.
# Usage: START=0 END=1070 BATCH_SIZE=500 bash build-batch.sh
# Intended to be called from CI matrix jobs.

cd "$(dirname "$0")"

BROWSE_DIR="browse"
STAGING_DIR=".browse-staging"
DIST_DIR=".vitepress/dist"
MAX_OLD_SPACE="${MAX_OLD_SPACE:-6144}"
BATCH_SIZE="${BATCH_SIZE:-500}"
START="${START:-0}"
END="${END:-0}"

# Stage all browse pages (move to staging)
echo "=== Staging browse pages ==="
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
find "$BROWSE_DIR" -name "*.md" ! -name "index.md" | while read -r f; do
  relpath="${f#$BROWSE_DIR/}"
  mkdir -p "$STAGING_DIR/$(dirname "$relpath")"
  mv "$f" "$STAGING_DIR/$relpath"
done

# Enumerate all staged files
mapfile -t all_files < <(find "$STAGING_DIR" -name "*.md" | sort)
total=${#all_files[@]}
actual_end=$((END > total ? total : END))
echo "=== Building pages $((START+1))-$actual_end of $total (batch size: $BATCH_SIZE) ==="

# Create the first batch's directory structure
for ((i=START; i<actual_end; i++)); do
  f="${all_files[$i]}"
  relpath="${f#$STAGING_DIR/}"
  mkdir -p "$BROWSE_DIR/$(dirname "$relpath")"
  cp "$f" "$BROWSE_DIR/$relpath"
done

first_count=$(find "$BROWSE_DIR" -name "*.md" ! -name "index.md" | wc -l | tr -d ' ')
echo "=== Initial build: $first_count pages ==="
NODE_OPTIONS="--max-old-space-size=$MAX_OLD_SPACE" npx vitepress build

# Save the initial dist as our base (has the CSS/JS/shell)
mkdir -p "$DIST_DIR-saved"
cp -r "$DIST_DIR/"* "$DIST_DIR-saved/"

# If we have more pages than fit in one batch, process in sequential batches
if [ "$first_count" -le "$BATCH_SIZE" ]; then
  echo "=== All $first_count pages fit in one batch ==="
  rm -rf "$STAGING_DIR"
  exit 0
fi

# Remove first batch, process remaining in batches
find "$BROWSE_DIR" -name "*.md" ! -name "index.md" -delete
find "$BROWSE_DIR" -type d -empty -delete 2>/dev/null || true

batch_num=0
for ((batch_start=START; batch_start<actual_end; batch_start+=BATCH_SIZE)); do
  batch_end=$((batch_start + BATCH_SIZE))
  if [ "$batch_end" -gt "$actual_end" ]; then batch_end=$actual_end; fi
  batch_num=$((batch_num + 1))

  echo ""
  echo "=== Batch $batch_num: pages $((batch_start+1))-$batch_end ==="

  # Copy this batch's files
  for ((i=batch_start; i<batch_end; i++)); do
    f="${all_files[$i]}"
    relpath="${f#$STAGING_DIR/}"
    mkdir -p "$BROWSE_DIR/$(dirname "$relpath")"
    cp "$f" "$BROWSE_DIR/$relpath"
  done

  batch_count=$(find "$BROWSE_DIR" -name "*.md" ! -name "index.md" | wc -l | tr -d ' ')
  echo "  Building $batch_count pages"

  NODE_OPTIONS="--max-old-space-size=$MAX_OLD_SPACE" npx vitepress build

  # Merge browse output into saved dist
  if [ -d "$DIST_DIR/browse" ]; then
    mkdir -p "$DIST_DIR-saved/browse"
    cp -r "$DIST_DIR/browse/"* "$DIST_DIR-saved/browse/" 2>/dev/null || true
    added=$(find "$DIST_DIR/browse" -name "*.html" ! -name "index.html" | wc -l | tr -d ' ')
    echo "  Added $added browse pages"
  fi

  # Remove this batch
  find "$BROWSE_DIR" -name "*.md" ! -name "index.md" -delete
  find "$BROWSE_DIR" -type d -empty -delete 2>/dev/null || true
  rm -rf "$DIST_DIR"
done

# Replace dist with merged output
rm -rf "$DIST_DIR"
mv "$DIST_DIR-saved" "$DIST_DIR"

# Clean up
rm -rf "$STAGING_DIR"

echo "=== Batch build complete ==="
