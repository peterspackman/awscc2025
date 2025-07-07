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
    Write-Host "Runs OCC lattice energy calculation for ice crystal"
    Write-Host "This script only works with OCC"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. Lattice energy calculation using pairwise summation"
    Write-Host "  2. Analysis of interaction convergence with distance"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Model: Use --model flag (ce-1p, sapt0, etc.)"
    Write-Host "  - Crystal structure: Modify ice.cif file"
    Write-Host "  - Cutoff radius: Edit script to add --radius option"
    Write-Host ""
    Write-Host "Expected results:"
    Write-Host "  - Lattice energy ~125 kJ/mol (for asymmetric unit)"
    Write-Host "  - Divide by 2 for per-molecule lattice energy (~62.8 kJ/mol)"
    Write-Host "  - Compare to experimental sublimation enthalpy ~54 kJ/mol"
    exit 1
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command occ -ErrorAction SilentlyContinue)) {
    Write-Host "Error: OCC not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Running OCC ice lattice energy calculation with model=$Model, threads=$Threads"
Write-Host ""

$output = & occ elat ice.cif --model=$Model --threads=$Threads 2>&1 | Tee-Object -FilePath ice_elat.stdout

Write-Host ""
Write-Host "Ice lattice energy calculation completed. Results saved to ice_elat.stdout"
Write-Host ""

# Extract lattice energy from output
$content = Get-Content ice_elat.stdout -Raw

$E_lat_total = if ($content -match "Final energy:\s+(-?\d+\.\d+)") { [double]$matches[1] } else { 0.0 }
$E_lat_unit = if ($content -match "Lattice energy:\s+(-?\d+\.\d+)") { [double]$matches[1] } else { 0.0 }

# Calculate per-molecule lattice energy (divide by 2 for ice asymmetric unit)
$E_lat_per_mol = $E_lat_unit / 2

# Calculate sublimation enthalpy estimate
$RT_298 = 8.314 * 298.15 / 1000  # R*T in kJ/mol
$two_RT = 2 * $RT_298
$H_sub_estimate = -1 * $E_lat_per_mol - $two_RT

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "LATTICE ENERGY ANALYSIS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Calculated lattice energies:"
Write-Host ("  Asymmetric unit:     {0:F2} kJ/mol" -f $E_lat_unit)
Write-Host ("  Per molecule:        {0:F2} kJ/mol" -f $E_lat_per_mol)
Write-Host ""
Write-Host "Thermodynamic estimates:"
Write-Host ("  2RT at 298K:         {0:F2} kJ/mol" -f $two_RT)
Write-Host ("  ΔH_sub estimate:     {0:F2} kJ/mol" -f $H_sub_estimate)
Write-Host ""
Write-Host "Experimental reference:"
Write-Host "  ΔH_sub (exp):        ~54 kJ/mol"
$diff = $H_sub_estimate - 54
$diff_percent = ($diff / 54) * 100
Write-Host ("  Difference:          {0:F2} kJ/mol ({1:F1}%)" -f $diff, $diff_percent)