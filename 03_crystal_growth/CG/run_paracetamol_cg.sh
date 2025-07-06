#!/usr/bin/env bash
set -e

MODEL="ce-1p"
SOLVENT="water"
RADIUS="4.1"
CG_RADIUS="4.1"
SURFACE_ENERGIES="10"
THREADS=6

usage() {
    echo "Usage: $0 [--model MODEL] [--solvent SOLVENT] [--radius R] [--cg-radius R] [--surface-energies N] [--threads N] [--help]"
    echo "  --model:           OCC interaction model (default: ce-1p)"
    echo "  --solvent:         Solvent for crystal growth (default: water)"
    echo "  --radius:          Crystal growth radius in Angstroms (default: 4.1)"
    echo "  --cg-radius:       Charge group radius in Angstroms (default: 4.1)"
    echo "  --surface-energies: Number of surface energies to calculate (default: 10)"
    echo "  --threads:         Number of threads (default: 6)"
    echo ""
    echo "Runs OCC crystal growth (CG) calculation for paracetamol"
    echo "This script only works with OCC"
    echo ""
    echo "The calculation performs:"
    echo "  1. Crystal growth simulation in specified solvent"
    echo "  2. Surface energy calculations for different crystal faces"
    echo "  3. Analysis of growth rates and morphology"
    echo ""
    echo "To customize the calculation:"
    echo "  - Crystal structure: Modify paracetamol.cif file"
    echo "  - Growth conditions: Use command-line flags"
    echo ""
    echo "Expected outputs:"
    echo "  - Surface energies for different crystal faces"
    echo "  - Growth morphology predictions"
    echo "  - Solvent effects on crystal growth"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --solvent)
            SOLVENT="$2"
            shift 2
            ;;
        --radius)
            RADIUS="$2"
            shift 2
            ;;
        --cg-radius)
            CG_RADIUS="$2"
            shift 2
            ;;
        --surface-energies)
            SURFACE_ENERGIES="$2"
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

echo "Running OCC paracetamol crystal growth calculation"
echo "  Model: $MODEL"
echo "  Solvent: $SOLVENT"
echo "  Radius: $RADIUS Å"
echo "  CG Radius: $CG_RADIUS Å"
echo "  Surface energies: $SURFACE_ENERGIES"
echo "  Threads: $THREADS"
echo ""

occ cg paracetamol.cif --model=$MODEL --solvent=$SOLVENT --radius=$RADIUS --cg-radius=$CG_RADIUS --surface-energies=$SURFACE_ENERGIES --threads=$THREADS | tee paracetamol_cg.stdout
