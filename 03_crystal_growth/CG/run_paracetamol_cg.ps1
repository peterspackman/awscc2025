param(
    [string]$Model = "ce-1p",
    [string]$Solvent = "water",
    [string]$Radius = "4.1",
    [string]$CgRadius = "4.1",
    [string]$SurfaceEnergies = "10",
    [int]$Threads = 6,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--model MODEL] [--solvent SOLVENT] [--radius R] [--cg-radius R] [--surface-energies N] [--threads N] [--help]"
    Write-Host "  --model:           OCC interaction model (default: ce-1p)"
    Write-Host "  --solvent:         Solvent for crystal growth (default: water)"
    Write-Host "  --radius:          Crystal growth radius in Angstroms (default: 4.1)"
    Write-Host "  --cg-radius:       Charge group radius in Angstroms (default: 4.1)"
    Write-Host "  --surface-energies: Number of surface energies to calculate (default: 10)"
    Write-Host "  --threads:         Number of threads (default: 6)"
    Write-Host ""
    Write-Host "Runs OCC crystal growth (CG) calculation for paracetamol"
    Write-Host "This script only works with OCC"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. Crystal growth simulation in specified solvent"
    Write-Host "  2. Surface energy calculations for different crystal faces"
    Write-Host "  3. Analysis of growth rates and morphology"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Crystal structure: Modify paracetamol.cif file"
    Write-Host "  - Growth conditions: Use command-line flags"
    Write-Host ""
    Write-Host "Expected outputs:"
    Write-Host "  - Surface energies for different crystal faces"
    Write-Host "  - Growth morphology predictions"
    Write-Host "  - Solvent effects on crystal growth"
    exit 1
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command occ -ErrorAction SilentlyContinue)) {
    Write-Host "Error: OCC not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Running OCC paracetamol crystal growth calculation"
Write-Host "  Model: $Model"
Write-Host "  Solvent: $Solvent"
Write-Host "  Radius: $Radius Å"
Write-Host "  CG Radius: $CgRadius Å"
Write-Host "  Surface energies: $SurfaceEnergies"
Write-Host "  Threads: $Threads"
Write-Host ""

$output = & occ cg paracetamol.cif --model=$Model --solvent=$Solvent --radius=$Radius --cg-radius=$CgRadius --surface-energies=$SurfaceEnergies --threads=$Threads 2>&1 | Tee-Object -FilePath paracetamol_cg.stdout