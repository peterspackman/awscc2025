#!/usr/bin/env bash
set -e

usage() {
    echo "Usage: $0 [--help]"
    echo ""
    echo "Runs ORCA BSSE calculation using bsse.inp file"
    echo "This script only works with ORCA"
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