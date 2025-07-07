param(
    [string]$Radius = "60.0",
    [int]$Threads = 1,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--radius RADIUS] [--threads N] [--help]"
    Write-Host "  --radius:  Cutoff radius in Angstroms (default: 60.0)"
    Write-Host "  --threads: Number of threads (default: 1)"
    Write-Host ""
    Write-Host "Runs OCC charge group (CG) calculation for NaCl crystal"
    Write-Host "This script only works with OCC"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. Coulomb lattice energy calculation using charge groups"
    Write-Host "  2. Analysis of convergence with cutoff radius"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Radius: Use --radius flag (try different values for convergence)"
    Write-Host "  - Crystal structure: Modify NaCl.cif file"
    Write-Host "  - Charges: Currently fixed to +1/-1 for Na+/Cl-"
    Write-Host ""
    Write-Host "Expected behavior:"
    Write-Host "  - Poor convergence due to ionic nature of crystal"
    Write-Host "  - Large fluctuations in lattice energy with radius"
    Write-Host "  - Demonstrates need for Ewald summation methods"
    Write-Host ""
    Write-Host "Note: This shows limitations of simple pairwise summation"
    Write-Host "      for ionic systems with long-range interactions"
    exit 0
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command occ -ErrorAction SilentlyContinue)) {
    Write-Host "Error: OCC not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Running OCC NaCl charge group calculation with radius=$Radius, threads=$Threads"
Write-Host ""

$output = & occ cg --atomic --charges=1,-1 NaCl.cif --radius=$Radius --threads=$Threads 2>&1 | Tee-Object -FilePath nacl_cg.stdout

Write-Host ""
Write-Host "NaCl charge group calculation completed. Results saved to nacl_cg.stdout"
Write-Host ""

# Extract cycle energies to show convergence issues
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "LATTICE ENERGY CONVERGENCE ANALYSIS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cycle-by-cycle lattice energies (kJ/mol):"

$content = Get-Content nacl_cg.stdout
$cycleLines = $content | Select-String -Pattern "Cycle.*lattice energy:" | Select-Object -First 20

foreach ($line in $cycleLines) {
    if ($line -match "Cycle\s+(\d+).*lattice energy:\s+(-?\d+\.\d+)") {
        $cycle = [int]$matches[1]
        $energy = [double]$matches[2]
        Write-Host ("  Cycle {0,2}: {1,10:F2} kJ/mol" -f $cycle, $energy)
    }
}

# Get final lattice energy if available
$finalMatch = $content | Select-String -Pattern "Final lattice energy:\s+(-?\d+\.\d+)" | Select-Object -Last 1
if ($finalMatch) {
    $final_energy = [double]$finalMatch.Matches[0].Groups[1].Value
    
    Write-Host ""
    Write-Host ("Final lattice energy: {0:F2} kJ/mol" -f $final_energy)
    
    # Calculate per formula unit (NaCl has 4 formula units per unit cell)
    $energy_per_fu = $final_energy / 4
    Write-Host ("Per formula unit:     {0:F2} kJ/mol" -f $energy_per_fu)
    
    Write-Host ""
    Write-Host "Experimental reference:"
    Write-Host "  Lattice energy (exp): -786 kJ/mol per formula unit"
    Write-Host "  Madelung constant for NaCl: 1.7476"
}

Write-Host ""
Write-Host "Analysis:"
Write-Host "  - Notice the large fluctuations between cycles"
Write-Host "  - Poor convergence due to long-range Coulomb interactions"
Write-Host "  - Demonstrates limitations of simple pairwise summation"
Write-Host "  - Try different --radius values to see convergence behavior"