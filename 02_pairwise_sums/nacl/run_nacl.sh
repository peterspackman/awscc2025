#!/usr/bin/env bash
set -e

RADIUS="60.0"
THREADS=1

usage() {
    echo "Usage: $0 [--radius RADIUS] [--threads N] [--help]"
    echo "  --radius:  Cutoff radius in Angstroms (default: 60.0)"
    echo "  --threads: Number of threads (default: 1)"
    echo ""
    echo "Runs OCC charge group (CG) calculation for NaCl crystal"
    echo "This script only works with OCC"
    echo ""
    echo "The calculation performs:"
    echo "  1. Coulomb lattice energy calculation using charge groups"
    echo "  2. Analysis of convergence with cutoff radius"
    echo ""
    echo "To customize the calculation:"
    echo "  - Radius: Use --radius flag (try different values for convergence)"
    echo "  - Crystal structure: Modify NaCl.cif file"
    echo "  - Charges: Currently fixed to +1/-1 for Na+/Cl-"
    echo ""
    echo "Expected behavior:"
    echo "  - Poor convergence due to ionic nature of crystal"
    echo "  - Large fluctuations in lattice energy with radius"
    echo "  - Demonstrates need for Ewald summation methods"
    echo ""
    echo "Note: This shows limitations of simple pairwise summation"
    echo "      for ionic systems with long-range interactions"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --radius)
            RADIUS="$2"
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

echo "Running OCC NaCl charge group calculation with radius=$RADIUS, threads=$THREADS"
echo ""

occ cg --atomic --charges=1,-1 NaCl.cif --radius=$RADIUS --threads=$THREADS | tee nacl_cg.stdout

echo ""
echo "NaCl charge group calculation completed. Results saved to nacl_cg.stdout"
echo ""

# Extract cycle energies to show convergence issues
echo "========================================="
echo "LATTICE ENERGY CONVERGENCE ANALYSIS"
echo "========================================="
echo ""
echo "Cycle-by-cycle lattice energies (kJ/mol):"
grep "Cycle.*lattice energy:" nacl_cg.stdout | head -20 | while read line; do
    cycle=$(echo $line | awk '{print $2}')
    energy=$(echo $line | awk '{print $5}')
    printf "  Cycle %2d: %10.2f kJ/mol\n" $cycle $energy
done

# Get final lattice energy if available
final_energy=$(grep "Final lattice energy:" nacl_cg.stdout | tail -1 | awk '{print $4}')
if [[ -n "$final_energy" ]]; then
    echo ""
    printf "Final lattice energy: %.2f kJ/mol\n" $final_energy
    
    # Calculate per formula unit (NaCl has 4 formula units per unit cell)
    energy_per_fu=$(echo "$final_energy / 4" | bc -l)
    printf "Per formula unit:     %.2f kJ/mol\n" $energy_per_fu
    
    echo ""
    echo "Experimental reference:"
    echo "  Lattice energy (exp): -786 kJ/mol per formula unit"
    echo "  Madelung constant for NaCl: 1.7476"
fi

echo ""
echo "Analysis:"
echo "  - Notice the large fluctuations between cycles"
echo "  - Poor convergence due to long-range Coulomb interactions"
echo "  - Demonstrates limitations of simple pairwise summation"
echo "  - Try different --radius values to see convergence behavior"