param(
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--help]"
    Write-Host ""
    Write-Host "Runs ORCA LED (Local Energy Decomposition) calculation"
    Write-Host "This script only works with ORCA"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Method/basis: Edit the '! dlpno-ccsd(t) cc-pvdz cc-pvdz/c cc-pvtz/jk' lines"
    Write-Host "  - Geometry: Modify the coordinate blocks in led_*.inp files"
    Write-Host "  - LED settings: Add/modify LED-specific keywords in led_dimer.inp"
    Write-Host "  - Other settings: Add ORCA keywords/blocks to input files"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. LED analysis on the dimer (led_dimer.inp)"
    Write-Host "  2. Reference calculation on monomer A (led_a.inp)"
    Write-Host "  3. Reference calculation on monomer B (led_b.inp)"
    Write-Host ""
    Write-Host "LED analysis decomposes interaction energy into:"
    Write-Host "  - Electrostatic, exchange, repulsion, and dispersion components"
    Write-Host "  - Orbital interaction terms"
    exit 0
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command orca -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ORCA not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Running ORCA LED calculation..."
Write-Host ""

Write-Host "Running LED analysis on dimer..."
$outputDimer = & orca led_dimer.inp 2>&1 | Tee-Object -FilePath led_dimer.stdout

Write-Host ""
Write-Host "Running reference calculation on monomer A..."
$outputA = & orca led_a.inp 2>&1 | Tee-Object -FilePath led_a.stdout

Write-Host ""
Write-Host "Running reference calculation on monomer B..."
$outputB = & orca led_b.inp 2>&1 | Tee-Object -FilePath led_b.stdout

Write-Host ""
Write-Host "LED calculation completed. Results saved to:"
Write-Host "  - led_dimer.stdout (LED analysis)"
Write-Host "  - led_a.stdout (monomer A reference)"
Write-Host "  - led_b.stdout (monomer B reference)"
Write-Host ""
Write-Host "Look for LED energy decomposition in led_dimer.stdout"
Write-Host "Search for 'FINAL SINGLE POINT ENERGY' for total energies"