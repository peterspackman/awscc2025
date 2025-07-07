param(
    [string]$Model = "ce-1p",
    [int]$Threads = 1,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--model MODEL] [--threads N] [--help]"
    Write-Host "  --model:   OCC interaction model (default: ce-1p)"
    Write-Host "  --threads: Number of threads (default: 1)"
    Write-Host ""
    Write-Host "Runs OCC lattice energy calculation for urea crystal"
    Write-Host "This script only works with OCC"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. Lattice energy calculation using pairwise summation"
    Write-Host "  2. Analysis of interaction convergence with distance"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Model: Use --model flag (ce-1p, sapt0, etc.)"
    Write-Host "  - Crystal structure: Modify urea.cif file"
    Write-Host "  - Cutoff radius: Edit script to add --radius option"
    Write-Host ""
    Write-Host "Expected results:"
    Write-Host "  - Compare calculated lattice energy to experimental reference"
    Write-Host "  - X23 reference: 102.1 kJ/mol (vibrational corrected)"
    Write-Host "  - Assess accuracy of pairwise interaction model"
    exit 1
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command occ -ErrorAction SilentlyContinue)) {
    Write-Host "Error: OCC not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Running OCC urea lattice energy calculation with model=$Model, threads=$Threads"
Write-Host ""

$output = & occ elat urea.cif --model=$Model --threads=$Threads 2>&1 | Tee-Object -FilePath urea_elat.stdout

Write-Host ""
Write-Host "Urea lattice energy calculation completed. Results saved to urea_elat.stdout"
Write-Host ""

# Extract lattice energy from output
$content = Get-Content urea_elat.stdout -Raw

$E_lat_total = if ($content -match "Final energy:\s+(-?\d+\.\d+)") { [double]$matches[1] } else { 0.0 }
$E_lat_unit = if ($content -match "Lattice energy:\s+(-?\d+\.\d+)") { [double]$matches[1] } else { 0.0 }

# Urea has 2 molecules per asymmetric unit typically
$moleculeMatches = [regex]::Matches($content, "Molecule.*total:")
$n_molecules = if ($moleculeMatches.Count -gt 0) { $moleculeMatches.Count } else { 1 }

# Calculate per-molecule lattice energy
$E_lat_per_mol = $E_lat_unit / $n_molecules

# X23 reference value
$X23_ref = -102.1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "LATTICE ENERGY ANALYSIS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Calculated lattice energies:"
Write-Host ("  Total:               {0:F2} kJ/mol" -f $E_lat_total)
Write-Host ("  Asymmetric unit:     {0:F2} kJ/mol" -f $E_lat_unit)
Write-Host ("  Per molecule:        {0:F2} kJ/mol ({1} molecules/unit)" -f $E_lat_per_mol, $n_molecules)
Write-Host ""
Write-Host "Experimental reference (X23 dataset):"
Write-Host ("  Vibrational corrected: {0:F1} kJ/mol" -f $X23_ref)
$diff = $E_lat_per_mol - $X23_ref
$diff_percent = ($diff / $X23_ref) * 100
Write-Host ("  Difference:           {0:F2} kJ/mol ({1:F1}%)" -f $diff, $diff_percent)
Write-Host ""
Write-Host "Analysis:"
Write-Host "  - X23 reference includes vibrational corrections"
Write-Host "  - Pairwise models may miss many-body polarization"
Write-Host "  - Crystal packing effects can be significant for urea"