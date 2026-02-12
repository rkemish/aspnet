#!/usr/bin/env bash
# ──────────────────────────────────────────────
# OWASP ZAP Baseline Scan
# Runs a passive scan against a target URL using the ZAP Docker image.
#
# Usage: ./zap-baseline.sh <target-url> <output-dir>
# ──────────────────────────────────────────────
set -euo pipefail

TARGET_URL="${1:?Usage: $0 <target-url> <output-dir>}"
OUTPUT_DIR="${2:?Usage: $0 <target-url> <output-dir>}"

echo "========================================="
echo "OWASP ZAP Baseline Scan"
echo "Target: $TARGET_URL"
echo "========================================="

mkdir -p "$OUTPUT_DIR"

# Run ZAP baseline scan (passive only — safe for every deployment)
# -t: target URL
# -r: HTML report filename
# -J: JSON report filename
# -I: don't return failure codes for warnings (we handle them separately)
docker run --rm \
  -v "$OUTPUT_DIR:/zap/wrk/:rw" \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
    -t "$TARGET_URL" \
    -r zap-baseline-report.html \
    -J zap-baseline-report.json \
    -I || true

echo "========================================="
echo "ZAP reports written to: $OUTPUT_DIR"
echo "========================================="
