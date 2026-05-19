#!/usr/bin/env bash
# Install smart contract audit tools
set -euo pipefail

echo "=== Smart Contract Audit Tools Setup ==="

# Check Python
if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 required" && exit 1
fi

# Install slither-analyzer
if ! command -v slither &>/dev/null; then
  echo "[+] Installing slither-analyzer..."
  pip3 install --quiet slither-analyzer
else
  echo "[✓] slither already installed: $(slither --version 2>&1 | head -1)"
fi

# Install solc-select for managing Solidity compiler versions
if ! command -v solc-select &>/dev/null; then
  echo "[+] Installing solc-select..."
  pip3 install --quiet solc-select
else
  echo "[✓] solc-select already installed"
fi

echo ""
echo "=== Setup complete ==="
echo "Usage: Run 'scripts/run_slither.sh <target_dir>' to analyze contracts"
