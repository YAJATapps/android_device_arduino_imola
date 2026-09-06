#!/usr/bin/env bash
#
# package_qdl.sh
# LineageOS 23.2 QDL Packaging Entry Point for Arduino Uno Q (Imola)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/tools/package_qdl.py"

if ! command -v python3 &>/dev/null; then
    echo "[-] ERROR: python3 is required."
    exit 1
fi

python3 "${PYTHON_SCRIPT}" --desktop "$@"
