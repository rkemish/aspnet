#!/usr/bin/env bash
# ──────────────────────────────────────────────
# SSL/TLS Scan using testssl.sh
# Validates TLS configuration of a target host.
#
# Usage: ./ssl-scan.sh <hostname> <output-dir>
# ──────────────────────────────────────────────
set -euo pipefail

HOSTNAME="${1:?Usage: $0 <hostname> <output-dir>}"
OUTPUT_DIR="${2:?Usage: $0 <hostname> <output-dir>}"

echo "========================================="
echo "SSL/TLS Scan (testssl.sh)"
echo "Target: $HOSTNAME"
echo "========================================="

mkdir -p "$OUTPUT_DIR"

# Install testssl.sh if not available
if ! command -v testssl &>/dev/null; then
  echo "Installing testssl.sh..."
  git clone --depth 1 https://github.com/drwetter/testssl.sh.git /tmp/testssl
  TESTSSL_CMD="/tmp/testssl/testssl.sh"
else
  TESTSSL_CMD="testssl"
fi

# Run testssl.sh with key checks:
# --protocols: check supported TLS versions
# --server-defaults: server certificate info
# --vulnerabilities: check for known TLS vulnerabilities
# --quiet: reduce verbose output
"$TESTSSL_CMD" \
  --protocols \
  --server-defaults \
  --vulnerabilities \
  --quiet \
  --htmlfile "$OUTPUT_DIR/ssl-scan-report.html" \
  --jsonfile "$OUTPUT_DIR/ssl-scan-report.json" \
  "$HOSTNAME" || true

echo "========================================="
echo "SSL scan reports written to: $OUTPUT_DIR"
echo "========================================="
