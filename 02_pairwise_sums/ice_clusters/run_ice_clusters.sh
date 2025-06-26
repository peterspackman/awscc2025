#!/usr/bin/env bash
set -e

METHOD="gfn2"
THREADS=1

usage() {
    echo "Usage: $0 [--method METHOD] [--threads N] [--help]"
    echo "  --method:  xTB method (default: gfn2, options: gfn1, gfn2, gfnff)"
    echo "  --threads: Number of threads (default: 1)"
    echo ""
    echo "Runs xTB calculations on ice cluster systems"
    echo "This script only works with xTB"
    echo ""
    echo "The calculation performs:"
    echo "  1. Central molecule calculation"
    echo "  2. Cluster calculations (4 and 8 neighbor shells)"
    echo "  3. Neighbor environment calculations (4 and 8 shells)"
    echo ""
    echo "To customize the calculation:"
    echo "  - Method: Use --method flag (gfn1, gfn2, gfnff)"
    echo "  - Geometry: Modify the .xyz coordinate files"
    echo "  - Additional radii: Add loops for different cluster sizes"
    echo ""
    echo "Results show how interaction energies converge with cluster size"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --method)
            METHOD="$2"
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

if ! command -v xtb >/dev/null 2>&1; then
    echo "Error: xTB not found in PATH"
    exit 1
fi

export OMP_NUM_THREADS=$THREADS
export OMP_STACKSIZE=16000

echo "Running xTB ice cluster analysis with method=$METHOD, threads=$THREADS"
echo ""

echo "Running central molecule calculation..."
xtb ice_central_molecule.xyz --${METHOD} | tee ice_central_molecule.stdout

echo ""
echo "Running cluster calculations..."
for r in 4 8; do
    echo "  Cluster with $r neighbor shells..."
    xtb ice_cluster_${r}.xyz --${METHOD} | tee ice_cluster_${r}.stdout
done

echo ""
echo "Running neighbor environment calculations..."
for r in 4 8; do
    echo "  Neighbors only with $r shells..."
    xtb ice_neighbors_${r}.xyz --${METHOD} | tee ice_neighbors_${r}.stdout
done

echo ""
echo "Ice cluster calculations completed. Results saved to stdout files."
echo ""

# Extract energies
E_central=$(grep "TOTAL ENERGY" ice_central_molecule.stdout | tail -1 | awk '{print $4}')
E_cluster_4=$(grep "TOTAL ENERGY" ice_cluster_4.stdout | tail -1 | awk '{print $4}')
E_cluster_8=$(grep "TOTAL ENERGY" ice_cluster_8.stdout | tail -1 | awk '{print $4}')
E_neighbors_4=$(grep "TOTAL ENERGY" ice_neighbors_4.stdout | tail -1 | awk '{print $4}')
E_neighbors_8=$(grep "TOTAL ENERGY" ice_neighbors_8.stdout | tail -1 | awk '{print $4}')

# Calculate interaction energies
E_int_4=$(echo "$E_cluster_4 - $E_central - $E_neighbors_4" | bc -l)
E_int_8=$(echo "$E_cluster_8 - $E_central - $E_neighbors_8" | bc -l)

# Calculate per-molecule interaction energies (divide by number of molecules)
# Cluster 4 has 5 molecules total (1 central + 4 neighbors)
# Cluster 8 has 9 molecules total (1 central + 8 neighbors)
E_int_per_mol_4=$(echo "$E_int_4 / 5" | bc -l)
E_int_per_mol_8=$(echo "$E_int_8 / 9" | bc -l)

# Convert to kJ/mol
E_int_4_kjmol=$(echo "$E_int_4 * 2625.4996" | bc -l)
E_int_8_kjmol=$(echo "$E_int_8 * 2625.4996" | bc -l)
E_int_per_mol_4_kjmol=$(echo "$E_int_per_mol_4 * 2625.4996" | bc -l)
E_int_per_mol_8_kjmol=$(echo "$E_int_per_mol_8 * 2625.4996" | bc -l)

echo "========================================="
echo "INTERACTION ENERGY ANALYSIS"
echo "========================================="
echo ""
echo "Total interaction energies:"
printf "  4-shell cluster:  %.6f hartree = %.2f kJ/mol\n" $E_int_4 $E_int_4_kjmol
printf "  8-shell cluster:  %.6f hartree = %.2f kJ/mol\n" $E_int_8 $E_int_8_kjmol
echo ""
echo "Per-molecule interaction energies:"
printf "  4-shell cluster:  %.6f hartree = %.2f kJ/mol per molecule\n" $E_int_per_mol_4 $E_int_per_mol_4_kjmol
printf "  8-shell cluster:  %.6f hartree = %.2f kJ/mol per molecule\n" $E_int_per_mol_8 $E_int_per_mol_8_kjmol
echo ""
echo "Convergence: $(echo "scale=1; ($E_int_8 - $E_int_4) * 100 / $E_int_8" | bc -l)% change from 4 to 8 shells"
