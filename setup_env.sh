#!/bin/bash
# Source this file to set up the workshop environment
# Usage: source setup_env.sh

WORKSHOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$WORKSHOP_DIR/bin:$PATH"

# Set OCC data path if share directory exists
if [[ -d "$WORKSHOP_DIR/share/occ" ]]; then
    export OCC_DATA_PATH="$WORKSHOP_DIR/share/occ"
fi

echo "Workshop environment set up:"
echo "  OCC binary: $(which occ 2>/dev/null || echo 'NOT FOUND')"
echo "  OCC data path: ${OCC_DATA_PATH:-'NOT SET'}"
