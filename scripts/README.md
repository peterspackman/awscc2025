# Workshop Scripts

This directory contains utility scripts for the AWSCC 2025 workshop.

## Scripts Available

### test_installation.sh
Tests that all software is properly installed and configured.

**Usage:**
```bash
./test_installation.sh
```

**What it tests:**
- OCC basic functionality
- Optional software (XTB, ORCA, Gaussian, Psi4)
- Python and UV tools
- Visualization software
- Workshop example files
- Environment variables

**Example output:**
```
=== AWSCC 2025 Installation Test ===
Testing OCC help... ✅ PASS
Testing OCC SCF help... ✅ PASS
Testing OCC CG help... ✅ PASS
Testing OCC SCF on water... ✅ PASS
XTB not found (optional)
ORCA not found (optional)
...
```

## Future Scripts

Additional analysis and utility scripts will be added here during workshop development:

- `analyze_dimers.py` - Analyze dimer interaction energies
- `plot_energy_decomposition.py` - Visualize SAPT energy components  
- `setup_crystal_calculations.sh` - Batch setup for crystal analysis
- `compare_methods.py` - Compare different computational methods

## Usage Notes

1. **Always run from workshop root directory:**
   ```bash
   cd awscc_workshop_2025
   ./scripts/test_installation.sh
   ```

2. **Source environment first:**
   ```bash
   source setup_env.sh
   ./scripts/test_installation.sh
   ```

3. **Make scripts executable if needed:**
   ```bash
   chmod +x scripts/*.sh
   ```

## Script Development

When adding new scripts:

1. **Add appropriate shebang:**
   ```bash
   #!/bin/bash
   # or
   #!/usr/bin/env python3
   ```

2. **Include error handling:**
   ```bash
   set -e  # Exit on error
   ```

3. **Document in this README**

4. **Test on multiple platforms if possible**

---

**Last Updated:** January 2025