# AWSCC 2025 - Intermolecular Interactions Workshop

This repository contains all materials for the Australian Winter School on Computational Chemistry (AWSCC) 2025 workshop on intermolecular interactions.

Workshop material and documentation: https://www.prs.wiki/docs/awscc_workshop

## Quick Start

```bash
# Clone and setup
git clone https://github.com/peterspackman/awscc_workshop_2025.git
cd awscc_workshop_2025

# Install OCC, XTB and other tools
./install/setup.sh       # Linux/macOS
.\install\setup.ps1      # Windows

# Activate environment
source setup_env.sh      # Linux/macOS
. .\setup_env.ps1         # Windows

# Test installation
./scripts/test_installation.sh    # Linux/macOS
.\scripts\test_installation.ps1   # Windows
```

## Workshop Content

1. **Pair Energies** (`01_pair_energies/`)
   - Water dimers with different methods
   - Basis set superposition error (BSSE)
   - CE-1P interaction model

2. **Pairwise Sums** (`02_pairwise_sums/`)
   - Water trimers: many-body vs pairwise
   - Ice lattice energy calculations
   - NaCl and urea crystal lattice energies
   - XTB ice cluster calculations

3. **Crystal Growth** (`03_crystal_growth/`)
   - Paracetamol crystal growth simulation
   - Solvation modeling (SMD)
