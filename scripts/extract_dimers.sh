#!/bin/bash

# Extract dimers from all crystal structures for workshop analysis
# This creates individual dimer XYZ files that we can analyze in detail

set -e

WORKSHOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"
cd "$WORKSHOP_DIR"

# Source environment
if [[ -f "setup_env.sh" ]]; then
    source setup_env.sh
fi

echo "=== Extracting Dimers from Crystal Structures ==="
echo ""

CRYSTALS=(
    "geometries/paracetamol.cif"
    "geometries/urea.cif" 
    "geometries/iceII.cif"
)

for crystal in "${CRYSTALS[@]}"; do
    if [[ ! -f "$crystal" ]]; then
        echo "Warning: $crystal not found, skipping..."
        continue
    fi
    
    basename=$(basename "$crystal" .cif)
    echo "Processing $basename crystal..."
    
    # Create temporary directory for this crystal's dimers
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Extract dimers (within 15 Å, reasonable cutoff)
    echo "  Extracting dimers within 15 Å..."
    if occ dimers "$WORKSHOP_DIR/$crystal" --cutoff=15.0 > dimers_output.txt 2>&1; then
        # Move generated dimer files to geometries with descriptive names
        dimer_count=0
        for dimer_file in dimer_*.xyz; do
            if [[ -f "$dimer_file" ]]; then
                ((dimer_count++))
                new_name="${basename}_dimer_$(printf "%03d" $dimer_count).xyz"
                cp "$dimer_file" "$WORKSHOP_DIR/geometries/$new_name"
                echo "    → $new_name"
            fi
        done
        echo "  Found $dimer_count unique dimers"
    else
        echo "  Error extracting dimers (see output below):"
        cat dimers_output.txt | head -10
    fi
    
    # Clean up
    cd "$WORKSHOP_DIR"
    rm -rf "$temp_dir"
    echo ""
done

echo "=== Dimer Extraction Complete ==="
echo ""
echo "Extracted dimer files are now in geometries/ directory:"
ls -la geometries/*_dimer_*.xyz 2>/dev/null || echo "No dimer files found"
echo ""
echo "Next: Analyze these dimers with detailed interaction energy calculations"