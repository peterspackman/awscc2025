#!/usr/bin/env bash
set -e

MODEL="ce-1p"
THREADS=1

usage() {
    echo "Usage: $0 [--model MODEL] [--threads N] [--help]"
    echo "  --model:   OCC interaction model (default: ce-1p)"
    echo "  --threads: Number of threads (default: 1)"
    echo ""
    echo "Runs OCC lattice energy calculation for ice crystal"
    echo "This script only works with OCC"
    echo ""
    echo "The calculation performs:"
    echo "  1. Lattice energy calculation using pairwise summation"
    echo "  2. Analysis of interaction convergence with distance"
    echo ""
    echo "To customize the calculation:"
    echo "  - Model: Use --model flag (ce-1p, sapt0, etc.)"
    echo "  - Crystal structure: Modify ice.cif file"
    echo "  - Cutoff radius: Edit script to add --radius option"
    echo ""
    echo "Expected results:"
    echo "  - Lattice energy ~125 kJ/mol (for asymmetric unit)"
    echo "  - Divide by 2 for per-molecule lattice energy (~62.8 kJ/mol)"
    echo "  - Compare to experimental sublimation enthalpy ~54 kJ/mol"
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

echo "Running OCC ice lattice energy calculation with model=$MODEL, threads=$THREADS"
echo ""

occ elat ice.cif --model=$MODEL --threads=$THREADS | tee ice_elat.stdout

echo ""
echo "Ice lattice energy calculation completed. Results saved to ice_elat.stdout"
echo ""

# Extract lattice energy from output
E_lat_total=$(grep "Final energy:" ice_elat.stdout | tail -1 | awk '{print $3}')
E_lat_unit=$(grep "Lattice energy:" ice_elat.stdout | tail -1 | awk '{print $3}')

# Calculate per-molecule lattice energy (divide by 2 for ice asymmetric unit)
E_lat_per_mol=$(echo "$E_lat_unit / 2" | bc -l)

# Calculate sublimation enthalpy estimate
RT_298=$(echo "8.314 * 298.15 / 1000" | bc -l)  # R*T in kJ/mol
two_RT=$(echo "2 * $RT_298" | bc -l)
H_sub_estimate=$(echo "-1 * $E_lat_per_mol - $two_RT" | bc -l)

echo "========================================="
echo "LATTICE ENERGY ANALYSIS"
echo "========================================="
echo ""
echo "Calculated lattice energies:"
printf "  Asymmetric unit:     %.2f kJ/mol\n" $E_lat_unit
printf "  Per molecule:        %.2f kJ/mol\n" $E_lat_per_mol
echo ""
echo "Thermodynamic estimates:"
printf "  2RT at 298K:         %.2f kJ/mol\n" $two_RT
printf "  ΔH_sub estimate:     %.2f kJ/mol\n" $H_sub_estimate
echo ""
echo "Experimental reference:"
echo "  ΔH_sub (exp):        ~54 kJ/mol"
printf "  Difference:          %.2f kJ/mol (%.1f%%)\n" $(echo "$H_sub_estimate - 54" | bc -l) $(echo "($H_sub_estimate - 54) * 100 / 54" | bc -l)
