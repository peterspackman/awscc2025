#!/usr/bin/env bash
export OMP_NUM_THREADS=1
export OMP_STACKSIZE=16000

xtb ice_central_molecule.xyz --gfn=2 | tee ice_central_molecule.stdout

for r in 4 8; do
    xtb ice_cluster_${r}.xyz --gfn=2 | tee ice_cluster_${r}.stdout
done

for r in 4 8; do
    xtb ice_neighbors_${r}.xyz --gfn=2 | tee ice_neighbors_${r}.stdout
done
