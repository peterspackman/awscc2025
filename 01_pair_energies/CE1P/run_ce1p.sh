#!/usr/bin/env bash
set -e

METHOD="wb97x"
BASIS="def2-svp"
THREADS=1

usage() {
    echo "Usage: $0 [--method METHOD] [--basis BASIS] [--threads N] [--help]"
    echo "  --method:  Quantum chemistry method (default: wb97x)"
    echo "  --basis:   Basis set (default: def2-svp)"
    echo "  --threads: Number of threads (default: 1)"
    echo ""
    echo "Runs OCC CE-1P calculation for pair interaction energy"
    echo "This script only works with OCC"
    echo ""
    echo "To customize the calculation:"
    echo "  - Method/basis: Use --method and --basis flags (applied to SCF steps)"
    echo "  - Geometry: Modify A.xyz and B.xyz coordinate files"
    echo "  - CE-1P model: Currently fixed to ce-1p, edit script to change"
    echo "  - Other SCF settings: Add to OCC command line in script"
    echo ""
    echo "The calculation performs:"
    echo "  1. SCF calculation on monomer A"
    echo "  2. SCF calculation on monomer B"
    echo "  3. CE-1P pair interaction calculation"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --method)
            METHOD="$2"
            shift 2
            ;;
        --basis)
            BASIS="$2"
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

echo "Running OCC CE-1P calculation with method=$METHOD, basis=$BASIS, threads=$THREADS"
echo ""

echo "Running monomer A calculation..."
occ scf A.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee A.stdout

echo ""
echo "Running monomer B calculation..."
occ scf B.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee B.stdout 

echo ""
echo "Running CE-1P pair interaction calculation..."
occ pair --model=ce-1p -a A.owf.json -b B.owf.json | tee pair.stdout

echo ""
echo "CE-1P calculation completed. Results saved to:"
echo "  - A.stdout (monomer A SCF)"
echo "  - B.stdout (monomer B SCF)"
echo "  - pair.stdout (CE-1P pair interaction)"
echo ""
echo "Extract interaction energies from pair.stdout"