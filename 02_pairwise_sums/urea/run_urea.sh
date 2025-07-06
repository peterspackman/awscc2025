#!/usr/bin/env bash
set -e

MODEL="ce-1p"
THREADS=1

usage() {
    echo "Usage: $0 [--model MODEL] [--threads N] [--help]"
    echo "  --model:   OCC interaction model (default: ce-1p)"
    echo "  --threads: Number of threads (default: 1)"
    echo ""
    echo "Runs OCC lattice energy calculation for urea crystal"
    echo "This script only works with OCC"
    echo ""
    echo "The calculation performs:"
    echo "  1. Lattice energy calculation using pairwise summation"
    echo "  2. Analysis of interaction convergence with distance"
    echo ""
    echo "To customize the calculation:"
    echo "  - Model: Use --model flag (ce-1p, sapt0, etc.)"
    echo "  - Crystal structure: Modify urea.cif file"
    echo "  - Cutoff radius: Edit script to add --radius option"
    echo ""
    echo "Expected results:"
    echo "  - Compare calculated lattice energy to experimental reference"
    echo "  - X23 reference: 102.1 kJ/mol (vibrational corrected)"
    echo "  - Assess accuracy of pairwise interaction model"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if ! command -v occ >/dev/null 2>&1; then
    echo "Error: OCC not found in PATH"
    exit 1
fi

echo "Running OCC urea lattice energy calculation with model=$MODEL, threads=$THREADS"
echo ""

occ elat urea.cif --model=$MODEL --threads=$THREADS | tee urea_elat.stdout

echo ""
echo "Urea lattice energy calculation completed. Results saved to urea_elat.stdout"
echo ""

# Extract lattice energy from output
E_lat_total=$(grep "Final energy:" urea_elat.stdout | tail -1 | awk '{print $3}')
E_lat_unit=$(grep "Lattice energy:" urea_elat.stdout | tail -1 | awk '{print $3}')

# Urea has 2 molecules per asymmetric unit typically
n_molecules=$(grep "Molecule.*total:" urea_elat.stdout | wc -l)
if [[ $n_molecules -eq 0 ]]; then
    n_molecules=1
fi

# Calculate per-molecule lattice energy
E_lat_per_mol=$(echo "$E_lat_unit / $n_molecules" | bc -l)

# X23 reference value
X23_ref=-102.1

echo "========================================="
echo "LATTICE ENERGY ANALYSIS"
echo "========================================="
echo ""
echo "Calculated lattice energies:"
printf "  Total:               %.2f kJ/mol\n" $E_lat_total
printf "  Asymmetric unit:     %.2f kJ/mol\n" $E_lat_unit
printf "  Per molecule:        %.2f kJ/mol (%d molecules/unit)\n" $E_lat_per_mol $n_molecules
echo ""
echo "Experimental reference (X23 dataset):"
printf "  Vibrational corrected: %.1f kJ/mol\n" $X23_ref
printf "  Difference:           %.2f kJ/mol (%.1f%%)\n" $(echo "$E_lat_per_mol - $X23_ref" | bc -l) $(echo "($E_lat_per_mol - $X23_ref) * 100 / $X23_ref" | bc -l)
echo ""
echo "Analysis:"
echo "  - X23 reference includes vibrational corrections"
echo "  - Pairwise models may miss many-body polarization"
echo "  - Crystal packing effects can be significant for urea"
