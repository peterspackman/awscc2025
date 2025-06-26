## Ionic crystals and the convergence of the pairwise sums

Look at the output for the lattice energy for NaCl here, particularly the fluctuations from step to step.

```
...
Cycle 1 lattice energy: -1790.7392690114798
Cycle 2 lattice energy: -2108.2292884553926
Cycle 3 lattice energy: -829.5108792548691
Cycle 4 lattice energy: -373.7963861233957
Cycle 5 lattice energy: 128.4122192726171
Cycle 6 lattice energy: -1417.1247621492298
Cycle 7 lattice energy: -446.811019079476
Cycle 8 lattice energy: -2630.5546761945325
Cycle 9 lattice energy: 249.2587887941001
Cycle 10 lattice energy: -1551.6741328112091
Cycle 11 lattice energy: -1775.8863329481844
Cycle 12 lattice energy: -1349.5363962282474
Cycle 13 lattice energy: -1072.664720683679
Cycle 14 lattice energy: -2709.0015095497324
Cycle 15 lattice energy: -2837.852869990011
Cycle 16 lattice energy: -846.8295141564438
Cycle 17 lattice energy: -846.8295141564438
...
```

Convergence is most certainly not good...

There are several reasons why this sum doesn't converge, but they are primarily associated with changes in the net charge or net dipole of the finite clusters as we expand.

The Ewald sum (and the Wolf sum) overcome this limitation.


