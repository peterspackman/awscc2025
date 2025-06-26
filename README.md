# AWSCC 2025 - Intermolecular Interactions Workshop

This repository contains all materials for the Australian Winter School on Computational Chemistry (AWSCC) 2025 workshop on "Intermolecular Interactions: From Theory to Practice".

## Workshop Overview

**Duration:** 1.5 hours  
**Instructor:** [Your Name]  
**Software:** OCC, XTB, optional QM packages  

## Repository Structure

```
awscc_workshop_2025/
```

## Quick Start

```bash
# Clone and setup
git clone https://github.com/peterspackman/awscc_workshop_2025.git
cd awscc_workshop_2025

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

0. **Setup and Installation** (5 min)
   - Installing OCC, XTB, and other tools
   - Verifying the computational environment

1. **Introduction to Intermolecular Interactions via Dimers** (30 min)
   - Theory: dispersion, electrostatic, exchange-repulsion, and other terms
   - Basis set superposition error
   - Rationalising intermolecular interactions via decomposition into these terms
   - Building up intermolecular interactions via approximation of these terms
   - The CE-1p model
   - Tight binding using GFN2-xTB

2. **From Dimers to Crystals** (15 min)
   - The success of the pairwise model for lattice energy estimation
   - The abject failure of the pairwise model for lattice energy estimation

3. **Implicit solvation and Crystal Growth** (25 min)
   - Water dimers from ice crystal: hydrogen bonding networks
   - Paracetamol dimers: pharmaceutical crystal interactions
   - Urea dimers: strong vs weak hydrogen bonds
   - Comparison of computational methods (OCC, XTB)

## Caveats
- This is not some endorsement of a specific DFT or wavefunction method or basis set for a use case. It's always worth checking out relevant literature for *your* purposes.
- We're going to gloss over many, many complications associated with geometry optimisation at various stages. We're focused on evaluating energies at a particular geometry and all the issues that brings. The geometry itself brings a whole new set of issues too!

## Available Dimer Structures

The `geometries/` directory contains extracted dimer pairs from crystal structures:

- **Ice dimers** (`ice_dimers/`): 9 unique H-bonding environments in water networks
- **Paracetamol dimers** (`paracetamol_dimers/`): 8 different interaction types including strong H-bonds and weak π-π interactions
- **Urea dimers** (`urea_dimers/`): 4 patterns showing cooperative hydrogen bonding

These dimers represent the full spectrum of intermolecular interactions found in real crystals, extracted directly from experimental structures using OCC.

## Software Requirements

- **OCC** (Open Computational Chemistry) - Primary tool for interaction energies, lattice energies, crystal growth
- **XTB** - Fast semi-empirical calculations for quick screening
- **Optional:** ORCA for advanced calculations (not strictly required but very valuable)
- **Visualization:** up to you - CrystalExplorer, Avogadro, VMD, or ChimeraX
