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
echo "Extract energies from the output to calculate BSSE-corrected interaction energy:"
echo "  E_int_uncorrected = E_dimer - E_monomer1 - E_monomer2"
echo "  E_int_corrected = E_dimer - E_monomer1_ghost - E_monomer2_ghost"
echo "  BSSE = E_int_uncorrected - E_int_corrected"