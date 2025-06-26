## OCC lattice energy

Occc reports the final lattice energy as:

```
...
 11.396  11.846         x,x-y,-3/2+z   -0.144    0.000    0.000   -0.000   -0.001   -0.145
 11.396  11.846          x,x-y,3/2+z   -0.144    0.000    0.000   -0.000   -0.001   -0.145
Molecule 1 total: -126.217 kJ/mol (4144 pairs)

Final energy: -125.590 kJ/mol
Lattice energy: -125.590 kJ/mol
...
```

This is the lattice energy for the molecules in the asymmetric unit. We'd normally treat the water molecules as equivalent (same chemistry) so we should actually divide this by 2 (note that this is *not* the same factor of 1/2 we'd normally have for double counting interactions).

So the lattice energy predicted by the (pairwise) ce-1p model is: -62.8 kJ/mol

From standard numbers for latent heat of fusion, vaporisation etc. the sublimation enthalpy for water is 54.1 kJ/mol

A conventional formula to estimate $Delta H_\text{sub}$ from $E_\text{lat}$ is:

$$ Delta H_\text{sub} = - E_\text{lat} - 2 R T $$

At 298.15 K we have $2 R T = 4.96$ kJ/mol.

So an estimate of $\Delta H_\text{sub} = 62.8 - 4.96 = 57.84 $ kJ/mol.

- Are our numbers for the lattice energy reasonable?
- What are we missing?
- What about vibrational motion contributions (how accurate is the $2 R T$ term, where does it come from)
- Is this ice crystal what we see in reality...?

see http://dx.doi.org/10.1063/1.4812819
