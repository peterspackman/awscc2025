#!/usr/bin/env bash
occ cg paracetamol.cif --model=ce-1p --solvent=water --radius=4.1 --cg-radius=4.1  --surface-energies=10 --threads=6 | tee paracetamol.stdout
