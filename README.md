# AWSCC 2025 - Intermolecular Interactions Workshop

This repository contains all materials for the Australian Winter School on Computational Chemistry (AWSCC) 2025 workshop on "Intermolecular Interactions: From Theory to Practice".

## Repository Structure

```
awscc_workshop_2025/
```

## Quick Start

```bash
# Clone and setup
git clone https://github.com/peterspackman/awscc_workshop_2025.git
cd awscc_workshop_2025

# can also download the source from the releases

# Install OCC, XTB and other tools
./install/setup.sh

# Activate environment
source setup_env.sh

# Test installation
./scripts/test_installation.sh

# Try calculations on different systems
occ scf water.xyz wb97x def2-svp
xtb water.xyz
```

## Workshop Structure

This 1.5-hour workshop covers:

0. **Setup and Installation**
   - Installing OCC, XTB, and other tools
   - Verifying the computational environment

1. **Introduction to Intermolecular Interactions via Dimers**
   - Theory: dispersion, electrostatic, exchange-repulsion, and other terms
   - Basis set superposition error
   - Building up intermolecular interactions via approximation of these terms
   - The CE-1p model

2. **From Dimers to Crystals**
   - The success of the pairwise model for lattice energy estimation
   - The abject failure of the pairwise model for lattice energy estimation

3. **Implicit solvation  and Crystal growth**
   - Paracetamol dimers: pharmaceutical crystal interactions
   - Urea dimers: strong vs weak hydrogen bonds
   - Comparison of computational methods (OCC, XTB)

## Caveats
- This is not some endorsement of a specific DFT or wavefunction method or basis set for a use case. It's always worth checking out relevant literature for *your* purposes.
- We're going to gloss over many, many complications associated with geometry optimisation at various stages. We're focused on evaluating energies at a particular geometry and all the issues that brings. The geometry itself brings a whole new set of issues too!

## Software Requirements

- **OCC** (Open Computational Chemistry) - Primary tool for interaction energies, lattice energies, crystal growth
- **XTB** - Fast semi-empirical calculations for quick screening
- **Optional:** ORCA for advanced calculations (not strictly required but very valuable)
- **Visualization:** up to you - CrystalExplorer, Avogadro, Ovito, ChimeraX etc..
