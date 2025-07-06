#!/usr/bin/env bash
set -e

METHOD="b3lyp"
BASIS="def2-svp"
SOLVENT="water"
THREADS=6
PROGRAM=""

usage() {
    echo "Usage: $0 [--program orca|occ|xtb] [--method METHOD] [--basis BASIS] [--solvent SOLVENT] [--threads N] [--help]"
    echo "  --program: Specify quantum chemistry program (orca, occ, or xtb)"
    echo "  --method:  Quantum chemistry method (default: b3lyp)"
    echo "             For xTB: gfn1, gfn2, gfnff (default: gfn2)"
    echo "  --basis:   Basis set (default: def2-svp) - ignored for xTB"
    echo "  --solvent: Solvent model (default: water)"
    echo "             ORCA: SMD(solvent), OCC: --solvent=solvent, xTB: ALPB(solvent)"
    echo "  --threads: Number of threads (default: 6)"
    echo ""
    echo "Runs solvation calculation for paracetamol"
    echo "Works with ORCA (SMD), OCC (SMD), and xTB (ALPB)"
    echo ""
    echo "The calculation performs:"
    echo "  1. Gas phase calculation"
    echo "  2. Solution phase calculation with solvation model"
    echo "  3. Solvation free energy calculation"
    echo ""
    echo "To customize the calculation:"
    echo "  - Method/basis: Use command-line flags"
    echo "  - Solvent: Use --solvent flag (water, ethanol, dmso, etc.)"
    echo "  - Geometry: Modify paracetamol.xyz file"
    echo ""
    echo "Expected outputs:"
    echo "  - Gas phase energy"
    echo "  - Solution phase energy"
    echo "  - Solvation free energy (ΔG_solv)"
    echo ""
    echo "If --program is not specified, will try orca first, then occ, then xtb"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --program)
            PROGRAM="$2"
            shift 2
            ;;
        --method)
            METHOD="$2"
            shift 2
            ;;
        --basis)
            BASIS="$2"
            shift 2
            ;;
        --solvent)
            SOLVENT="$2"
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

check_program() {
    command -v "$1" >/dev/null 2>&1
}

detect_program() {
    if [[ -n "$PROGRAM" ]]; then
        if ! check_program "$PROGRAM"; then
            echo "Error: Specified program '$PROGRAM' not found in PATH"
            exit 1
        fi
        echo "$PROGRAM"
    else
        if check_program "orca"; then
            echo "orca"
        elif check_program "occ"; then
            echo "occ"
        elif check_program "xtb"; then
            echo "xtb"
        else
            echo "Error: Neither 'orca', 'occ', nor 'xtb' found in PATH"
            exit 1
        fi
    fi
}

run_orca() {
    echo "Using ORCA with method=$METHOD, basis=$BASIS, solvent=$SOLVENT"
    echo ""
    
    # Create ORCA input files (update existing ones with new method/basis/solvent)
    echo "! $METHOD $BASIS" > gas.inp
    echo "" >> gas.inp
    echo "* XYZFILE 0 1 paracetamol.xyz" >> gas.inp
    echo "" >> gas.inp
    if [[ $THREADS -gt 1 ]]; then
        echo "%pal" >> gas.inp
        echo "nprocs $THREADS" >> gas.inp
        echo "end" >> gas.inp
    fi
    
    # Convert solvent name to uppercase for ORCA (ORCA expects uppercase)
    SOLVENT_UPPER=$(echo "$SOLVENT" | tr '[:lower:]' '[:upper:]')
    echo "! $METHOD $BASIS SMD($SOLVENT_UPPER)" > smd.inp
    echo "" >> smd.inp  
    echo "* XYZFILE 0 1 paracetamol.xyz" >> smd.inp
    echo "" >> smd.inp
    if [[ $THREADS -gt 1 ]]; then
        echo "%pal" >> smd.inp
        echo "nprocs $THREADS" >> smd.inp
        echo "end" >> smd.inp
    fi
    
    # Run gas phase calculation
    echo "Running gas phase calculation..."
    orca gas.inp | tee gas.stdout
    
    # Run solution phase calculation
    echo ""
    echo "Running solution phase calculation (SMD)..."
    orca smd.inp | tee smd.stdout
    
    # Extract energies
    E_gas=$(grep "FINAL SINGLE POINT ENERGY" gas.stdout | awk '{print $5}')
    E_sol=$(grep "FINAL SINGLE POINT ENERGY" smd.stdout | awk '{print $5}')
    
    analyze_results_orca
}

run_occ() {
    echo "Using OCC with method=$METHOD, basis=$BASIS, solvent=$SOLVENT"
    echo ""
    
    # Run gas phase calculation
    echo "Running gas phase calculation..."
    occ scf paracetamol.xyz $METHOD $BASIS --threads=$THREADS | tee gas.stdout
    
    # Run solution phase calculation
    echo ""
    echo "Running solution phase calculation (SMD)..."
    occ scf paracetamol.xyz $METHOD $BASIS --solvent=$SOLVENT --threads=$THREADS | tee smd.stdout
    
    # Extract energies
    E_gas=$(grep "^total" gas.stdout | tail -1 | awk '{print $2}')
    E_sol=$(grep "^total" smd.stdout | tail -1 | awk '{print $2}')
    
    analyze_results_occ
}

run_xtb() {
    # Set default method for xTB if using DFT
    if [[ "$METHOD" == "b3lyp" ]]; then
        METHOD="gfn2"
    fi
    
    echo "Using xTB with method=$METHOD, solvent=$SOLVENT (basis set ignored)"
    echo ""
    
    export OMP_NUM_THREADS=$THREADS
    export OMP_STACKSIZE=16000
    
    # Run gas phase calculation
    echo "Running gas phase calculation..."
    xtb paracetamol.xyz --${METHOD} | tee gas.stdout
    
    # Run solution phase calculation with ALPB
    echo ""
    echo "Running solution phase calculation (ALPB)..."
    xtb paracetamol.xyz --${METHOD} --alpb $SOLVENT | tee smd.stdout
    
    # Extract energies
    E_gas=$(grep "TOTAL ENERGY" gas.stdout | tail -1 | awk '{print $4}')
    E_sol=$(grep "TOTAL ENERGY" smd.stdout | tail -1 | awk '{print $4}')
    
    analyze_results_xtb
}

analyze_results_orca() {
    # Calculate solvation free energy in hartree
    G_solv=$(echo "$E_sol - $E_gas" | bc -l)
    
    # Convert to kJ/mol
    G_solv_kjmol=$(echo "$G_solv * 2625.4996" | bc -l)
    
    echo ""
    echo "========================================="
    echo "SOLVATION FREE ENERGY ANALYSIS"
    echo "========================================="
    echo ""
    echo "Total energies:"
    printf "  Gas phase:      %.6f hartree\n" $E_gas
    printf "  Solution phase: %.6f hartree\n" $E_sol
    echo ""
    echo "Solvation free energy:"
    printf "  ΔG_solv = %.6f hartree = %.2f kJ/mol\n" $G_solv $G_solv_kjmol
    
    # Check for SMD breakdown in ORCA output
    if grep -q "Solvation" smd.stdout; then
        echo ""
        echo "SMD contributions:"
        grep -A5 "Solvation" smd.stdout | grep -E "Electrostatic|CDS|Dispersion" | head -3
    fi
    
    print_analysis
}

analyze_results_occ() {
    # Calculate solvation free energy in hartree
    G_solv=$(echo "$E_sol - $E_gas" | bc -l)
    
    # Convert to kJ/mol
    G_solv_kjmol=$(echo "$G_solv * 2625.4996" | bc -l)
    
    # Extract SMD contributions if available
    if grep -q "SMD solvation" smd.stdout; then
        E_elec=$(grep "electrostatic" smd.stdout | tail -1 | awk '{print $NF}')
        E_cds=$(grep "CDS" smd.stdout | tail -1 | awk '{print $NF}')
    fi
    
    echo ""
    echo "========================================="
    echo "SOLVATION FREE ENERGY ANALYSIS"
    echo "========================================="
    echo ""
    echo "Total energies:"
    printf "  Gas phase:      %.6f hartree\n" $E_gas
    printf "  Solution phase: %.6f hartree\n" $E_sol
    echo ""
    echo "Solvation free energy:"
    printf "  ΔG_solv = %.6f hartree = %.2f kJ/mol\n" $G_solv $G_solv_kjmol
    
    if [[ -n "$E_elec" ]]; then
        echo ""
        echo "SMD contributions:"
        printf "  Electrostatic:  %.2f kJ/mol\n" $E_elec
        printf "  CDS:            %.2f kJ/mol\n" $E_cds
    fi
    
    print_analysis
}

analyze_results_xtb() {
    # Calculate solvation free energy in hartree
    G_solv=$(echo "$E_sol - $E_gas" | bc -l)
    
    # Convert to kJ/mol
    G_solv_kjmol=$(echo "$G_solv * 2625.4996" | bc -l)
    
    echo ""
    echo "========================================="
    echo "SOLVATION FREE ENERGY ANALYSIS"
    echo "========================================="
    echo ""
    echo "Total energies:"
    printf "  Gas phase:      %.6f hartree\n" $E_gas
    printf "  Solution phase: %.6f hartree\n" $E_sol
    echo ""
    echo "Solvation free energy:"
    printf "  ΔG_solv = %.6f hartree = %.2f kJ/mol\n" $G_solv $G_solv_kjmol
    
    echo ""
    echo "ALPB solvation model:"
    echo "  - Analytical linearized Poisson-Boltzmann approach"
    echo "  - Fast approximate continuum solvation"
    echo "  - Good for screening and qualitative trends"
    
    print_analysis
}

print_analysis() {
    echo ""
    echo "Solubility analysis:"
    echo "  Experimental solubility of paracetamol in water: ~15 g/L at 25°C"
    echo ""
    echo "  Note: ΔG_solv relates to solubility through:"
    echo "  log S = (ΔG_fusion - ΔG_solv) / (2.303 RT)"
    echo ""
    echo "  A 5.7 kJ/mol error in ΔG corresponds to ~1 order of magnitude in solubility"
    
    # Calculate approximate log S if we have typical values
    RT_298=$(echo "8.314 * 298.15 / 1000" | bc -l)  # R*T in kJ/mol
    echo ""
    printf "  At 298K: RT = %.2f kJ/mol\n" $RT_298
    echo "  For accurate solubility: need ΔG_fusion from crystal structure"
}

echo "SMD calculations completed. Results saved to gas.stdout and smd.stdout"
echo ""

SELECTED_PROGRAM=$(detect_program)

case $SELECTED_PROGRAM in
    orca)
        run_orca
        ;;
    occ)
        run_occ
        ;;
    xtb)
        run_xtb
        ;;
esac