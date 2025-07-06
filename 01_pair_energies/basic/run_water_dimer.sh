#!/usr/bin/env bash
set -e

METHOD="hf"
BASIS="3-21g"
THREADS=1
PROGRAM=""

usage() {
    echo "Usage: $0 [--program orca|occ] [--method METHOD] [--basis BASIS] [--threads N]"
    echo "  --program: Specify quantum chemistry program (orca or occ)"
    echo "  --method:  Quantum chemistry method (default: hf)"
    echo "  --basis:   Basis set (default: 3-21g)"
    echo "  --threads: Number of threads (default: 1)"
    echo ""
    echo "If --program is not specified, will try orca first, then occ"
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
        else
            echo "Error: Neither 'orca' nor 'occ' found in PATH"
            exit 1
        fi
    fi
}

run_orca() {
    echo "Using ORCA"
    
    if [[ "$METHOD" != "hf" || "$BASIS" != "3-21g" ]]; then
        echo "Warning: ORCA uses input files (A.inp, B.inp, AB.inp) with predefined method/basis."
        echo "         The --method and --basis arguments are ignored for ORCA."
        echo "         To use different settings, manually edit the .inp files."
        echo ""
    fi
    
    echo -n "A: "
    orca A.inp | tee A.stdout
    E_A=$(grep "FINAL SINGLE POINT ENERGY" A.stdout | awk '{print $5}')
    echo "total                                $E_A"
    
    echo -n "B: "
    orca B.inp | tee B.stdout
    E_B=$(grep "FINAL SINGLE POINT ENERGY" B.stdout | awk '{print $5}')
    echo "total                                $E_B"
    
    echo -n "AB: "
    orca AB.inp | tee AB.stdout
    E_AB=$(grep "FINAL SINGLE POINT ENERGY" AB.stdout | awk '{print $5}')
    echo "total                               $E_AB"
    
    # Calculate interaction energy in hartree
    E_int=$(echo "$E_AB - $E_A - $E_B" | bc -l)
    
    # Convert to kJ/mol (1 hartree = 2625.4996 kJ/mol)
    E_int_kjmol=$(echo "$E_int * 2625.4996" | bc -l)
    
    echo ""
    echo "Interaction Energy:"
    printf "  ΔE = %.9f hartree\n" $E_int
    printf "  ΔE = %.2f kJ/mol\n" $E_int_kjmol
}

run_occ() {
    echo "Using OCC"
    
    echo -n "A: "
    E_A=$(occ scf A.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee A.stdout | grep '^total' | awk '{print $2}')
    echo "total                                $E_A"

    echo -n "B: "  
    E_B=$(occ scf B.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee B.stdout | grep '^total' | awk '{print $2}')
    echo "total                                $E_B"

    echo -n "AB: "
    E_AB=$(occ scf AB.xyz --threads=${THREADS} ${METHOD} ${BASIS} | tee AB.stdout | grep '^total' | awk '{print $2}')
    echo "total                               $E_AB"

    # Calculate interaction energy in hartree
    E_int=$(echo "$E_AB - $E_A - $E_B" | bc -l)

    # Convert to kJ/mol (1 hartree = 2625.4996 kJ/mol)
    E_int_kjmol=$(echo "$E_int * 2625.4996" | bc -l)

    echo ""
    echo "Interaction Energy:"
    printf "  ΔE = %.9f hartree\n" $E_int
    printf "  ΔE = %.2f kJ/mol\n" $E_int_kjmol
}

SELECTED_PROGRAM=$(detect_program)

case $SELECTED_PROGRAM in
    orca)
        run_orca
        ;;
    occ)
        run_occ
        ;;
esac