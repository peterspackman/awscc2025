#!/usr/bin/env bash
set -e

usage() {
    echo "Usage: $0 [--help]"
    echo ""
    echo "Runs ORCA LED (Local Energy Decomposition) calculation"
    echo "This script only works with ORCA"
    echo ""
    echo "To customize the calculation:"
    echo "  - Method/basis: Edit the '! dlpno-ccsd(t) cc-pvdz cc-pvdz/c cc-pvtz/jk' lines"
    echo "  - Geometry: Modify the coordinate blocks in led_*.inp files"
    echo "  - LED settings: Add/modify LED-specific keywords in led_dimer.inp"
    echo "  - Other settings: Add ORCA keywords/blocks to input files"
    echo ""
    echo "The calculation performs:"
    echo "  1. LED analysis on the dimer (led_dimer.inp)"
    echo "  2. Reference calculation on monomer A (led_a.inp)"
    echo "  3. Reference calculation on monomer B (led_b.inp)"
    echo ""
    echo "LED analysis decomposes interaction energy into:"
    echo "  - Electrostatic, exchange, repulsion, and dispersion components"
    echo "  - Orbital interaction terms"
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

echo "Running ORCA LED calculation..."
echo ""

echo "Running LED analysis on dimer..."
orca led_dimer.inp | tee led_dimer.stdout

echo ""
echo "Running reference calculation on monomer A..."
orca led_a.inp | tee led_a.stdout

echo ""
echo "Running reference calculation on monomer B..."
orca led_b.inp | tee led_b.stdout

echo ""
echo "LED calculation completed. Results saved to:"
echo "  - led_dimer.stdout (LED analysis)"
echo "  - led_a.stdout (monomer A reference)"
echo "  - led_b.stdout (monomer B reference)"
echo ""
echo "Look for LED energy decomposition in led_dimer.stdout"
echo "Search for 'FINAL SINGLE POINT ENERGY' for total energies"