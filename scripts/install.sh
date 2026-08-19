#!/bin/bash
# ============================================================
# Legacy install wrapper
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_INSTALLER="$SCRIPT_DIR/universal-installer/install.sh"

echo -e "\033[1;33m[WARN]\033[0m The monolithic install.sh has been deprecated."
echo -e "\033[1;33m[WARN]\033[0m Redirecting to the new Universal Installer at:"
echo -e "       $NEW_INSTALLER\n"

sleep 1

exec bash "$NEW_INSTALLER" "$@"
