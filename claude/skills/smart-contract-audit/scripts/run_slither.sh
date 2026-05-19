#!/usr/bin/env bash
# Run slither static analysis on Solidity contracts
set -euo pipefail

TARGET="${1:-.}"
OUTPUT_DIR="${2:-slither-output}"

if ! command -v slither &>/dev/null; then
  echo "ERROR: slither not found. Run scripts/setup_tools.sh first."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "=== Running Slither on: $TARGET ==="

# Run slither with JSON output for structured results
slither "$TARGET" \
  --json "$OUTPUT_DIR/slither-results.json" \
  --checklist \
  2>&1 | tee "$OUTPUT_DIR/slither-log.txt" || true

# Also generate human-readable output
slither "$TARGET" \
  --print human-summary \
  2>&1 | tee "$OUTPUT_DIR/slither-summary.txt" || true

echo ""
echo "=== Slither analysis complete ==="
echo "Results: $OUTPUT_DIR/slither-results.json"
echo "Summary: $OUTPUT_DIR/slither-summary.txt"
