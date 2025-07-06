#!/usr/bin/env bash
set -e

usage() {
    echo "Usage: $0 [--help]"
    echo ""
    echo "Runs ORCA BSSE calculation using bsse.inp file"
    echo "This script only works with ORCA"
    echo ""
    echo "To customize the calculation:"
    echo "  - Method/basis: Edit the '! wb97x def2-qzvp' lines in bsse.inp"
    echo "  - Geometry: Modify the coordinate blocks in bsse.inp"
    echo "  - Other settings: Add ORCA keywords/blocks to bsse.inp"
    echo ""
    echo "The input file contains multiple jobs for BSSE correction:"
    echo "  1. Monomer A alone"
    echo "  2. Monomer B alone"
    echo "  3. Dimer AB"
    echo "  4. Monomer A with ghost atoms of B"
    echo "  5. Monomer B with ghost atoms of A"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if ! command -v orca >/dev/null 2>&1; then
    echo "Error: ORCA not found in PATH"
    exit 1
fi

echo "Running ORCA BSSE calculation..."
orca bsse.inp | tee bsse.stdout

echo ""
echo "BSSE calculation completed. Results saved to bsse.stdout"
echo ""

# Extract energies from ORCA output
echo "Extracting energies from BSSE calculation..."

# Check if the output file exists and has content
if [[ ! -s bsse.stdout ]]; then
    echo "Error: bsse.stdout is empty or does not exist"
    exit 1
fi

# Try different patterns to extract energies
# First try the summary section pattern
E_mon1=$(grep "Energy for.*monomer from job 1" bsse.stdout | awk '{print $8}')
E_mon2=$(grep "Energy for.*monomer from job 2" bsse.stdout | awk '{print $8}')
E_dimer=$(grep "Energy for.*dimer from job 3" bsse.stdout | awk '{print $8}')
E_mon1_ghost=$(grep "Energy for.*monomer_ghost from job 4" bsse.stdout | awk '{print $8}')
E_mon2_ghost=$(grep "Energy for.*monomer_ghost from job 5" bsse.stdout | awk '{print $8}')

# If that fails, try extracting from FINAL SINGLE POINT ENERGY lines
if [[ -z "$E_mon1" || -z "$E_mon2" || -z "$E_dimer" || -z "$E_mon1_ghost" || -z "$E_mon2_ghost" ]]; then
    echo "Summary energies not found, extracting from individual job outputs..."
    
    # Extract all FINAL SINGLE POINT ENERGY lines in order
    energies=($(grep "FINAL SINGLE POINT ENERGY" bsse.stdout | awk '{print $5}'))
    
    if [[ ${#energies[@]} -ge 5 ]]; then
        E_mon1=${energies[0]}
        E_mon2=${energies[1]}
        E_dimer=${energies[2]}
        E_mon1_ghost=${energies[3]}
        E_mon2_ghost=${energies[4]}
    else
        echo "Error: Could not extract all 5 energies from output"
        echo "Found ${#energies[@]} energies, need 5"
        echo "Please check bsse.stdout for calculation errors"
        exit 1
    fi
fi

# Verify all energies were extracted successfully
if [[ -z "$E_mon1" || -z "$E_mon2" || -z "$E_dimer" || -z "$E_mon1_ghost" || -z "$E_mon2_ghost" ]]; then
    echo "Error: Failed to extract energies from output"
    echo "Please check the bsse.stdout file for calculation errors"
    exit 1
fi

echo ""
echo "========================================="
echo "BSSE CORRECTION ANALYSIS"
echo "========================================="
echo ""
echo "Individual job energies:"
printf "  Monomer A:           %.9f hartree\n" $E_mon1
printf "  Monomer B:           %.9f hartree\n" $E_mon2
printf "  Dimer AB:            %.9f hartree\n" $E_dimer
printf "  Monomer A + ghost B: %.9f hartree\n" $E_mon1_ghost
printf "  Monomer B + ghost A: %.9f hartree\n" $E_mon2_ghost

# Calculate interaction energies
E_int_uncorrected=$(echo "$E_dimer - $E_mon1 - $E_mon2" | bc -l)
E_int_corrected=$(echo "$E_dimer - $E_mon1_ghost - $E_mon2_ghost" | bc -l)
BSSE=$(echo "$E_int_uncorrected - $E_int_corrected" | bc -l)

# Convert to kJ/mol
E_int_uncorrected_kjmol=$(echo "$E_int_uncorrected * 2625.4996" | bc -l)
E_int_corrected_kjmol=$(echo "$E_int_corrected * 2625.4996" | bc -l)
BSSE_kjmol=$(echo "$BSSE * 2625.4996" | bc -l)

echo ""
echo "Interaction energies:"
printf "  Uncorrected:    %.6f hartree = %7.2f kJ/mol\n" $E_int_uncorrected $E_int_uncorrected_kjmol
printf "  BSSE-corrected: %.6f hartree = %7.2f kJ/mol\n" $E_int_corrected $E_int_corrected_kjmol

echo ""
echo "BSSE correction:"
printf "  BSSE = %.6f hartree = %7.2f kJ/mol\n" $BSSE $BSSE_kjmol
printf "  BSSE = %.1f%% of uncorrected interaction energy\n" $(echo "scale=1; $BSSE / $E_int_uncorrected * 100" | bc -l)

echo ""
echo "Analysis:"
if (( $(echo "$BSSE_kjmol > 2.0" | bc -l) )); then
    echo "  - Significant BSSE (>2 kJ/mol) - correction is important"
elif (( $(echo "$BSSE_kjmol > 1.0" | bc -l) )); then
    echo "  - Moderate BSSE (1-2 kJ/mol) - correction recommended"
else
    echo "  - Small BSSE (<1 kJ/mol) - correction less critical"
fi

echo "  - Use BSSE-corrected value for publication"
echo "  - BSSE decreases with larger basis sets"