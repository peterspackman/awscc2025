#!/usr/bin/env bash
set -e

METHOD="hf"
BASIS="3-21g"
THREADS=1
PROGRAM=""

usage() {
    echo "Usage: $0 [--program orca|occ|xtb] [--method METHOD] [--basis BASIS] [--threads N] [--help]"
    echo "  --program: Specify quantum chemistry program (orca, occ, or xtb)"
    echo "  --method:  Quantum chemistry method (default: hf)"
    echo "             For xTB: gfn1, gfn2, gfnff (default: gfn2)"
    echo "  --basis:   Basis set (default: 3-21g) - ignored for xTB"
    echo "  --threads: Number of threads (default: 1)"
    echo ""
    echo "Calculates water trimer interaction energy and compares:"
    echo "  1. Direct trimer calculation: E_ABC - E_A - E_B - E_C"
    echo "  2. Sum of pairwise interactions: E_AB + E_AC + E_BC - 2*(E_A + E_B + E_C)"
    echo ""
    echo "This shows many-body effects vs pairwise approximation"
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
    echo "Using ORCA with method=$METHOD, basis=$BASIS"
    echo ""
    
    # Create input files for ORCA
    for mol in A B C AB AC BC ABC; do
        echo "! $METHOD $BASIS" > ${mol}.inp
        echo "*xyzfile 0 1 ${mol}.xyz" >> ${mol}.inp
        echo "" >> ${mol}.inp
    done
    
    # Run calculations
    echo "Running monomer calculations..."
    for mol in A B C; do
        echo "  $mol:"
        orca ${mol}.inp | tee ${mol}.stdout
        E_MOL=$(grep "FINAL SINGLE POINT ENERGY" ${mol}.stdout | awk '{print $5}')
        echo "    Energy: $E_MOL"
    done
    
    echo ""
    echo "Running dimer calculations..."
    for mol in AB AC BC; do
        echo "  $mol:"
        orca ${mol}.inp | tee ${mol}.stdout
        E_MOL=$(grep "FINAL SINGLE POINT ENERGY" ${mol}.stdout | awk '{print $5}')
        echo "    Energy: $E_MOL"
    done
    
    echo ""
    echo "Running trimer calculation..."
    echo "  ABC:"
    orca ABC.inp | tee ABC.stdout
    E_ABC=$(grep "FINAL SINGLE POINT ENERGY" ABC.stdout | awk '{print $5}')
    echo "    Energy: $E_ABC"
    
    # Extract energies and calculate interaction energies
    E_A=$(grep "FINAL SINGLE POINT ENERGY" A.stdout | awk '{print $5}')
    E_B=$(grep "FINAL SINGLE POINT ENERGY" B.stdout | awk '{print $5}')
    E_C=$(grep "FINAL SINGLE POINT ENERGY" C.stdout | awk '{print $5}')
    E_AB=$(grep "FINAL SINGLE POINT ENERGY" AB.stdout | awk '{print $5}')
    E_AC=$(grep "FINAL SINGLE POINT ENERGY" AC.stdout | awk '{print $5}')
    E_BC=$(grep "FINAL SINGLE POINT ENERGY" BC.stdout | awk '{print $5}')
    
    analyze_results
}

run_occ() {
    echo "Using OCC with method=$METHOD, basis=$BASIS"
    echo ""
    
    echo "Running monomer calculations..."
    for mol in A B C; do
        echo "  $mol:"
        E_MOL=$(occ scf ${mol}.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee ${mol}.stdout | grep '^total' | awk '{print $2}')
        echo "    Energy: $E_MOL"
    done
    
    echo ""
    echo "Running dimer calculations..."
    for mol in AB AC BC; do
        echo "  $mol:"
        E_MOL=$(occ scf ${mol}.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee ${mol}.stdout | grep '^total' | awk '{print $2}')
        echo "    Energy: $E_MOL"
    done
    
    echo ""
    echo "Running trimer calculation..."
    echo "  ABC:"
    E_ABC=$(occ scf ABC.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee ABC.stdout | grep '^total' | awk '{print $2}')
    echo "    Energy: $E_ABC"
    
    # Extract energies
    E_A=$(grep '^total' A.stdout | awk '{print $2}')
    E_B=$(grep '^total' B.stdout | awk '{print $2}')
    E_C=$(grep '^total' C.stdout | awk '{print $2}')
    E_AB=$(grep '^total' AB.stdout | awk '{print $2}')
    E_AC=$(grep '^total' AC.stdout | awk '{print $2}')
    E_BC=$(grep '^total' BC.stdout | awk '{print $2}')
    
    analyze_results
}

run_xtb() {
    # Set default method for xTB if using HF
    if [[ "$METHOD" == "hf" ]]; then
        METHOD="gfn2"
    fi
    
    echo "Using xTB with method=$METHOD (basis set ignored)"
    echo ""
    
    export OMP_NUM_THREADS=$THREADS
    export OMP_STACKSIZE=16000
    
    echo "Running monomer calculations..."
    for mol in A B C; do
        echo "  $mol:"
        xtb ${mol}.xyz --${METHOD} | tee ${mol}.stdout
        E_MOL=$(grep "TOTAL ENERGY" ${mol}.stdout | tail -1 | awk '{print $4}')
        echo "    Energy: $E_MOL"
    done
    
    echo ""
    echo "Running dimer calculations..."
    for mol in AB AC BC; do
        echo "  $mol:"
        xtb ${mol}.xyz --${METHOD} | tee ${mol}.stdout
        E_MOL=$(grep "TOTAL ENERGY" ${mol}.stdout | tail -1 | awk '{print $4}')
        echo "    Energy: $E_MOL"
    done
    
    echo ""
    echo "Running trimer calculation..."
    echo "  ABC:"
    xtb ABC.xyz --${METHOD} | tee ABC.stdout
    E_ABC=$(grep "TOTAL ENERGY" ABC.stdout | tail -1 | awk '{print $4}')
    echo "    Energy: $E_ABC"
    
    # Extract energies
    E_A=$(grep "TOTAL ENERGY" A.stdout | tail -1 | awk '{print $4}')
    E_B=$(grep "TOTAL ENERGY" B.stdout | tail -1 | awk '{print $4}')
    E_C=$(grep "TOTAL ENERGY" C.stdout | tail -1 | awk '{print $4}')
    E_AB=$(grep "TOTAL ENERGY" AB.stdout | tail -1 | awk '{print $4}')
    E_AC=$(grep "TOTAL ENERGY" AC.stdout | tail -1 | awk '{print $4}')
    E_BC=$(grep "TOTAL ENERGY" BC.stdout | tail -1 | awk '{print $4}')
    
    analyze_results
}

analyze_results() {
    echo ""
    echo "========================================="
    echo "INTERACTION ENERGY ANALYSIS"
    echo "========================================="
    
    # Calculate pairwise interaction energies
    E_int_AB=$(echo "$E_AB - $E_A - $E_B" | bc -l)
    E_int_AC=$(echo "$E_AC - $E_A - $E_C" | bc -l)
    E_int_BC=$(echo "$E_BC - $E_B - $E_C" | bc -l)
    
    # Calculate direct trimer interaction energy
    E_int_trimer=$(echo "$E_ABC - $E_A - $E_B - $E_C" | bc -l)
    
    # Calculate sum of pairwise interactions
    E_int_pairwise=$(echo "$E_int_AB + $E_int_AC + $E_int_BC" | bc -l)
    
    # Calculate many-body contribution
    E_many_body=$(echo "$E_int_trimer - $E_int_pairwise" | bc -l)
    
    # Convert to kJ/mol
    E_int_AB_kjmol=$(echo "$E_int_AB * 2625.4996" | bc -l)
    E_int_AC_kjmol=$(echo "$E_int_AC * 2625.4996" | bc -l)
    E_int_BC_kjmol=$(echo "$E_int_BC * 2625.4996" | bc -l)
    E_int_trimer_kjmol=$(echo "$E_int_trimer * 2625.4996" | bc -l)
    E_int_pairwise_kjmol=$(echo "$E_int_pairwise * 2625.4996" | bc -l)
    E_many_body_kjmol=$(echo "$E_many_body * 2625.4996" | bc -l)
    
    echo ""
    echo "Individual pairwise interactions:"
    printf "  E_int(A-B) = %.6f hartree = %.2f kJ/mol\n" $E_int_AB $E_int_AB_kjmol
    printf "  E_int(A-C) = %.6f hartree = %.2f kJ/mol\n" $E_int_AC $E_int_AC_kjmol
    printf "  E_int(B-C) = %.6f hartree = %.2f kJ/mol\n" $E_int_BC $E_int_BC_kjmol
    
    echo ""
    echo "Trimer interaction energies:"
    printf "  Direct trimer:     %.6f hartree = %.2f kJ/mol\n" $E_int_trimer $E_int_trimer_kjmol
    printf "  Sum of pairs:      %.6f hartree = %.2f kJ/mol\n" $E_int_pairwise $E_int_pairwise_kjmol
    printf "  Many-body effect:  %.6f hartree = %.2f kJ/mol\n" $E_many_body $E_many_body_kjmol
    
    echo ""
    echo "Many-body contribution: $(echo "scale=1; $E_many_body * 100 / $E_int_trimer" | bc -l)% of total interaction"
}

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