param(
    [string]$Method = "gfn2",
    [int]$Threads = 1,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--method METHOD] [--threads N] [--help]"
    Write-Host "  --method:  xTB method (default: gfn2, options: gfn1, gfn2, gfnff)"
    Write-Host "  --threads: Number of threads (default: 1)"
    Write-Host ""
    Write-Host "Runs xTB calculations on ice cluster systems"
    Write-Host "This script only works with xTB"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. Central molecule calculation"
    Write-Host "  2. Cluster calculations (4 and 8 neighbor shells)"
    Write-Host "  3. Neighbor environment calculations (4 and 8 shells)"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Method: Use --method flag (gfn1, gfn2, gfnff)"
    Write-Host "  - Geometry: Modify the .xyz coordinate files"
    Write-Host "  - Additional radii: Add loops for different cluster sizes"
    Write-Host ""
    Write-Host "Results show how interaction energies converge with cluster size"
    exit 0
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command xtb -ErrorAction SilentlyContinue)) {
    Write-Host "Error: xTB not found in PATH" -ForegroundColor Red
    exit 1
}

$env:OMP_NUM_THREADS = $Threads
$env:OMP_STACKSIZE = "16000"

Write-Host "Running xTB ice cluster analysis with method=$Method, threads=$Threads"
Write-Host ""

Write-Host "Running central molecule calculation..."
$outputCentral = & xtb ice_central_molecule.xyz "--$Method" 2>&1 | Tee-Object -FilePath ice_central_molecule.stdout

Write-Host ""
Write-Host "Running cluster calculations..."
foreach ($r in @(4, 8)) {
    Write-Host "  Cluster with $r neighbor shells..."
    $output = & xtb "ice_cluster_${r}.xyz" "--$Method" 2>&1 | Tee-Object -FilePath "ice_cluster_${r}.stdout"
}

Write-Host ""
Write-Host "Running neighbor environment calculations..."
foreach ($r in @(4, 8)) {
    Write-Host "  Neighbors only with $r shells..."
    $output = & xtb "ice_neighbors_${r}.xyz" "--$Method" 2>&1 | Tee-Object -FilePath "ice_neighbors_${r}.stdout"
}

Write-Host ""
Write-Host "Ice cluster calculations completed. Results saved to stdout files."
Write-Host ""

# Extract energies
$E_central = if ((Get-Content ice_central_molecule.stdout | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1)) { [double]$_.Matches[0].Groups[1].Value } else { 0 }
$E_cluster_4 = if ((Get-Content ice_cluster_4.stdout | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1)) { [double]$_.Matches[0].Groups[1].Value } else { 0 }
$E_cluster_8 = if ((Get-Content ice_cluster_8.stdout | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1)) { [double]$_.Matches[0].Groups[1].Value } else { 0 }
$E_neighbors_4 = if ((Get-Content ice_neighbors_4.stdout | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1)) { [double]$_.Matches[0].Groups[1].Value } else { 0 }
$E_neighbors_8 = if ((Get-Content ice_neighbors_8.stdout | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1)) { [double]$_.Matches[0].Groups[1].Value } else { 0 }

# Calculate interaction energies
$E_int_4 = $E_cluster_4 - $E_central - $E_neighbors_4
$E_int_8 = $E_cluster_8 - $E_central - $E_neighbors_8

# Calculate per-molecule interaction energies (divide by number of molecules)
# Cluster 4 has 5 molecules total (1 central + 4 neighbors)
# Cluster 8 has 9 molecules total (1 central + 8 neighbors)
$E_int_per_mol_4 = $E_int_4 / 5
$E_int_per_mol_8 = $E_int_8 / 9

# Convert to kJ/mol
$hartree_to_kjmol = 2625.4996
$E_int_4_kjmol = $E_int_4 * $hartree_to_kjmol
$E_int_8_kjmol = $E_int_8 * $hartree_to_kjmol
$E_int_per_mol_4_kjmol = $E_int_per_mol_4 * $hartree_to_kjmol
$E_int_per_mol_8_kjmol = $E_int_per_mol_8 * $hartree_to_kjmol

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "INTERACTION ENERGY ANALYSIS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total interaction energies:"
Write-Host ("  4-shell cluster:  {0:F6} hartree = {1:F2} kJ/mol" -f $E_int_4, $E_int_4_kjmol)
Write-Host ("  8-shell cluster:  {0:F6} hartree = {1:F2} kJ/mol" -f $E_int_8, $E_int_8_kjmol)
Write-Host ""
Write-Host "Per-molecule interaction energies:"
Write-Host ("  4-shell cluster:  {0:F6} hartree = {1:F2} kJ/mol per molecule" -f $E_int_per_mol_4, $E_int_per_mol_4_kjmol)
Write-Host ("  8-shell cluster:  {0:F6} hartree = {1:F2} kJ/mol per molecule" -f $E_int_per_mol_8, $E_int_per_mol_8_kjmol)
Write-Host ""
if ($E_int_8 -ne 0) {
    $convergence = (($E_int_8 - $E_int_4) / $E_int_8) * 100
    Write-Host ("Convergence: {0:F1}% change from 4 to 8 shells" -f $convergence)
}