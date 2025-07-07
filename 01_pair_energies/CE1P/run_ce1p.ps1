param(
    [string]$Method = "wb97x",
    [string]$Basis = "def2-svp",
    [int]$Threads = 1,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--method METHOD] [--basis BASIS] [--threads N] [--help]"
    Write-Host "  --method:  Quantum chemistry method (default: wb97x)"
    Write-Host "  --basis:   Basis set (default: def2-svp)"
    Write-Host "  --threads: Number of threads (default: 1)"
    Write-Host ""
    Write-Host "Runs OCC CE-1P calculation for pair interaction energy"
    Write-Host "This script only works with OCC"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Method/basis: Use --method and --basis flags (applied to SCF steps)"
    Write-Host "  - Geometry: Modify A.xyz and B.xyz coordinate files"
    Write-Host "  - CE-1P model: Currently fixed to ce-1p, edit script to change"
    Write-Host "  - Other SCF settings: Add to OCC command line in script"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. SCF calculation on monomer A"
    Write-Host "  2. SCF calculation on monomer B"
    Write-Host "  3. CE-1P pair interaction calculation"
    exit 1
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command occ -ErrorAction SilentlyContinue)) {
    Write-Host "Error: OCC not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Running OCC CE-1P calculation with method=$Method, basis=$Basis, threads=$Threads"
Write-Host ""

Write-Host "Running monomer A calculation..."
$outputA = & occ scf A.xyz --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath A.stdout

Write-Host ""
Write-Host "Running monomer B calculation..."
$outputB = & occ scf B.xyz --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath B.stdout

Write-Host ""
Write-Host "Running CE-1P pair interaction calculation..."
$outputPair = & occ pair --model=ce-1p -a A.owf.json -b B.owf.json 2>&1 | Tee-Object -FilePath pair.stdout

Write-Host ""
Write-Host "CE-1P calculation completed. Results saved to:"
Write-Host "  - A.stdout (monomer A SCF)"
Write-Host "  - B.stdout (monomer B SCF)"
Write-Host "  - pair.stdout (CE-1P pair interaction)"
Write-Host ""
Write-Host "Extract interaction energies from pair.stdout"