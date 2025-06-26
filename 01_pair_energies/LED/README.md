# Local Energy Decomposition (LED) Analysis

Local Energy Decomposition (LED) is a powerful analysis tool within the DLPNO-CCSD(T) framework that decomposes the total interaction energy between molecular fragments into physically meaningful contributions. Unlike perturbative methods like SAPT, LED remains valid across the entire potential energy surface regardless of interaction strength.

## Method Overview

The LED scheme decomposes the binding energy between fragments into several key components:

**ΔE = ΔE_geo-prep + ΔE_el-prep^ref + E_elstat^ref + E_exch^ref + ΔE^C-CCSD_non-dispersion + E^C-CCSD_dispersion + ΔE^C-(T)_int**

Where:
- **ΔE_geo-prep**: Geometric preparation energy (strain energy)
- **ΔE_el-prep^ref**: Electronic preparation energy at the reference level
- **E_elstat^ref**: Electrostatic interactions between fragments
- **E_exch^ref**: Exchange interactions (Pauli repulsion)
- **ΔE^C-CCSD_non-dispersion**: Non-dispersive correlation effects (charge transfer, etc.)
- **E^C-CCSD_dispersion**: London dispersion interactions
- **ΔE^C-(T)_int**: Triples correction to interaction energy

## Water Dimer LED Analysis Results

### Individual Fragment Energies

**Water molecule A**: -76.241193014 Eh  
**Water molecule B**: -76.241159280 Eh

### LED Energy Decomposition

From the DLPNO-CCSD(T)/def2-SVP calculation:

**Reference Energy Components:**
- **Electrostatic interaction**: -0.035456 Eh = **-22.25 kcal/mol = -93.10 kJ/mol**
  - Dominant attractive term from permanent charge distributions
- **Exchange interaction**: -0.005835 Eh = **-3.66 kcal/mol = -15.31 kJ/mol**
  - Quantum mechanical exchange stabilization

**Correlation Energy Components:**
- **Dispersion (strong pairs)**: -0.001137 Eh = **-0.71 kcal/mol = -2.98 kJ/mol**
- **Dispersion (weak pairs)**: -0.000018 Eh = **-0.01 kcal/mol = -0.05 kJ/mol**
- **Total Dispersion**: **-0.72 kcal/mol = -3.03 kJ/mol**

**Charge Transfer Effects:**
- Fragment A → Fragment B: -0.000506 Eh = **-0.32 kcal/mol**
- Fragment B → Fragment A: -0.004879 Eh = **-3.06 kcal/mol**
- **Total Charge Transfer**: **-3.38 kcal/mol = -14.14 kJ/mol**

### Total Interaction Energy

**LED Total Interaction**: -0.043943 Eh = **-27.58 kcal/mol = -115.4 kJ/mol**

**Binding Energy** (relative to separated molecules): **-6.92 kcal/mol = -28.95 kJ/mol**

## Physical Interpretation

1. **Electrostatic interactions dominate** (-22.25 kcal/mol), consistent with hydrogen bonding where partial charges on H and O drive the attraction

2. **Exchange interactions** provide modest stabilization (-3.66 kcal/mol), overcoming Pauli repulsion at the optimal distance

3. **Dispersion interactions are small** (-0.72 kcal/mol) but non-negligible, typical for hydrogen-bonded systems

4. **Charge transfer is significant** (-3.38 kcal/mol), indicating substantial electron delocalization from the lone pairs of the proton acceptor to the σ* orbital of the proton donor

The total binding energy of ~7 kcal/mol is characteristic of a moderately strong hydrogen bond in water dimers, in excellent agreement with experimental and high-level computational benchmarks.

## Comparison with Other Methods

The LED binding energy can be compared with the BSSE-corrected energy from conventional methods:
- **LED binding energy**: -6.92 kcal/mol  
- **BSSE-corrected DFT** (from BSSE calculation): -5.57 kcal/mol

LED provides a more detailed breakdown of the physical origins of the interaction while maintaining the accuracy of coupled cluster methods.

## Further Reading

For more details on the LED method:
- Original LED paper: [J. Chem. Theory Comput. 2016, 12, 4778-4792](https://doi.org/10.1021/acs.jctc.6b00523)
- Hydrogen bonding analysis: [Beilstein J. Org. Chem. 2018, 14, 919](https://doi.org/10.3762/bjoc.14.79)
- Method comparison: [Int. J. Quantum Chem. 2021, 121, e26339](https://doi.org/10.1002/qua.26339)

## Questions to Consider

- How do the LED components change with different hydrogen bond strengths?
- What role does charge transfer play in different types of non-covalent interactions?
- How does the dispersion contribution compare between hydrogen bonds and van der Waals complexes?