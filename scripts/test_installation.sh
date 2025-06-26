#!/bin/bash

# Test script for AWSCC 2025 workshop installation
# Verifies that all required software is working correctly

set -e

WORKSHOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSHOP_DIR"

echo "=== AWSCC 2025 Installation Test ==="
echo "Workshop directory: $WORKSHOP_DIR"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_command() {
    local name="$1"
    local command="$2"
    local expected_pattern="$3"
    
    echo -n "Testing $name... "
    
    if output=$(eval "$command" 2>&1); then
        if [[ -z "$expected_pattern" ]] || echo "$output" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}✓${NC}"
            return 0
        else
            echo -e "${RED}✗${NC} (unexpected output)"
            echo "Expected pattern: $expected_pattern"
            echo "Got: $output"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} (command failed)"
        echo "Error: $output"
        return 1
    fi
}

# Source environment if available
if [[ -f "setup_env.sh" ]]; then
    echo -e "${YELLOW}Loading workshop environment...${NC}"
    source setup_env.sh
    echo ""
fi

# Test OCC
echo "=== Testing OCC ==="

if [[ -f "geometries/water.xyz" ]]; then
    echo ""
    echo "=== Testing OCC calculation ==="
    echo -n "Testing OCC SCF on water... "
    
    TEMP_DIR=$(mktemp -d)
    cp geometries/water.xyz "$TEMP_DIR/"
    
    if cd "$TEMP_DIR" && occ scf water.xyz rhf 3-21g > occ_output.txt 2>&1; then
        # Extract energy from output
        ENERGY=$(grep "^total" occ_output.txt | awk '{print $2}')
        if [[ -n "$ENERGY" ]]; then
            echo -e "${GREEN}✓${NC} (E = $ENERGY hartree)"
        else
            echo -e "${YELLOW}⚠ (completed but no energy found)${NC}"
        fi
    else
        echo -e "${RED}✗${NC}"
    fi
    
    rm -rf "$TEMP_DIR"
    cd "$WORKSHOP_DIR"
fi

echo ""

# Test optional software
echo "=== Testing Optional Software ==="

# XTB
if command -v xtb &> /dev/null; then
    echo -n "Testing XTB calculation... "
    
    TEMP_DIR=$(mktemp -d)
    cp geometries/water.xyz "$TEMP_DIR/"
    
    if cd "$TEMP_DIR" && xtb water.xyz --sp > xtb_output.txt 2>&1; then
        # Extract energy from output
        ENERGY=$(grep "TOTAL ENERGY" xtb_output.txt | awk '{print $4}')
        if [[ -n "$ENERGY" ]]; then
            echo -e "${GREEN}✓${NC} (E = $ENERGY hartree)"
        else
            echo -e "${YELLOW}⚠ (completed but no energy found)${NC}"
        fi
    else
        echo -e "${RED}✗${NC}"
    fi
    
    rm -rf "$TEMP_DIR"
    cd "$WORKSHOP_DIR"
else
    echo -e "${YELLOW}XTB not found (optional)${NC}"
fi

# ORCA
if command -v orca &> /dev/null; then
    echo -n "Testing ORCA calculation... "
    
    TEMP_DIR=$(mktemp -d)
    cat > "$TEMP_DIR/orca_test.inp" << 'EOF'
! HF 3-21G
* xyz 0 1
O 0.0 0.0 0.0
H -0.757 0.586 0.0
H 0.757 0.586 0.0
*
EOF
    
    if cd "$TEMP_DIR" && orca orca_test.inp > orca_test.out 2>&1; then
        # Extract energy from output
        ENERGY=$(grep "FINAL SINGLE POINT ENERGY" orca_test.out | awk '{print $5}')
        if [[ -n "$ENERGY" ]]; then
            echo -e "${GREEN}✓${NC} (E = $ENERGY hartree)"
        else
            echo -e "${YELLOW}⚠ (completed but no energy found)${NC}"
        fi
    else
        # Check if it at least started
        if grep -q "ORCA" "$TEMP_DIR/orca_test.out" 2>/dev/null; then
            echo -e "${YELLOW}⚠ (found but may need license/setup)${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
    fi
    
    rm -rf "$TEMP_DIR"
    cd "$WORKSHOP_DIR"
else
    echo -e "${YELLOW}ORCA not found (optional)${NC}"
fi

# Gaussian
if command -v g16 &> /dev/null; then
    GAUSSIAN_CMD="g16"
elif command -v g09 &> /dev/null; then
    GAUSSIAN_CMD="g09"
else
    GAUSSIAN_CMD=""
fi

if [[ -n "$GAUSSIAN_CMD" ]]; then
    echo -n "Testing Gaussian calculation... "
    
    TEMP_DIR=$(mktemp -d)
    cat > "$TEMP_DIR/gaussian_test.gjf" << 'EOF'
# HF/3-21G

Water molecule test

0 1
O 0.0 0.0 0.0
H -0.757 0.586 0.0
H 0.757 0.586 0.0

EOF
    
    if cd "$TEMP_DIR" && $GAUSSIAN_CMD gaussian_test.gjf > gaussian_test.log 2>&1; then
        # Extract energy from output
        ENERGY=$(grep "SCF Done:" gaussian_test.log | tail -1 | awk '{print $5}')
        if [[ -n "$ENERGY" ]]; then
            echo -e "${GREEN}✓${NC} (E = $ENERGY hartree)"
        else
            echo -e "${YELLOW}⚠ (completed but no energy found)${NC}"
        fi
    else
        echo -e "${RED}✗${NC}"
    fi
    
    rm -rf "$TEMP_DIR"
    cd "$WORKSHOP_DIR"
else
    echo -e "${YELLOW}Gaussian not found (optional)${NC}"
fi

# Psi4
if command -v psi4 &> /dev/null; then
    echo -n "Testing Psi4 calculation... "
    
    TEMP_DIR=$(mktemp -d)
    cat > "$TEMP_DIR/psi4_test.py" << 'EOF'
import psi4

psi4.set_output_file("psi4_output.txt", False)

molecule = psi4.geometry("""
0 1
O 0.0 0.0 0.0
H -0.757 0.586 0.0
H 0.757 0.586 0.0
""")

energy = psi4.energy('hf/3-21g')
print(f"ENERGY: {energy}")
EOF
    
    if cd "$TEMP_DIR" && python3 psi4_test.py > psi4_result.txt 2>&1; then
        # Extract energy from output
        ENERGY=$(grep "ENERGY:" psi4_result.txt | awk '{print $2}')
        if [[ -n "$ENERGY" ]]; then
            echo -e "${GREEN}✓${NC} (E = $ENERGY hartree)"
        else
            echo -e "${YELLOW}⚠ (completed but no energy found)${NC}"
        fi
    else
        echo -e "${RED}✗${NC}"
    fi
    
    rm -rf "$TEMP_DIR"
    cd "$WORKSHOP_DIR"
else
    echo -e "${YELLOW}Psi4 not found (optional)${NC}"
fi

echo ""

# Test Python and tools
echo "=== Testing Python Tools ==="

if command -v python3 &> /dev/null; then
    test_command "Python 3" "python3 --version" "Python 3"
else
    echo -e "${YELLOW}Python 3 not found${NC}"
fi

if command -v uv &> /dev/null; then
    test_command "UV tool" "uv --version" ""
else
    echo -e "${YELLOW}UV not found${NC}"
fi

echo ""

# Test file structure
echo "=== Testing Workshop Files ==="

test_files=(
    "geometries/paracetamol.cif"
    "geometries/urea.cif"
    "geometries/ice.cif"
    "geometries/water.xyz"
    "geometries/benzene.xyz"
    "geometries/methane.xyz"
    "geometries/water_dimer.xyz"
)

for file in "${test_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file missing${NC}"
    fi
done

echo ""
echo "Ready to start the workshop? Check out geometries/ directory!"