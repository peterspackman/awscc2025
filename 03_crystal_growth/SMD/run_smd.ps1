param(
    [string]$Program = "",
    [string]$Method = "b3lyp",
    [string]$Basis = "def2-svp",
    [string]$Solvent = "water",
    [int]$Threads = 6,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--program orca|occ|xtb] [--method METHOD] [--basis BASIS] [--solvent SOLVENT] [--threads N] [--help]"
    Write-Host "  --program: Specify quantum chemistry program (orca, occ, or xtb)"
    Write-Host "  --method:  Quantum chemistry method (default: b3lyp)"
    Write-Host "             For xTB: gfn1, gfn2, gfnff (default: gfn2)"
    Write-Host "  --basis:   Basis set (default: def2-svp) - ignored for xTB"
    Write-Host "  --solvent: Solvent model (default: water)"
    Write-Host "             ORCA: SMD(solvent), OCC: --solvent=solvent, xTB: ALPB(solvent)"
    Write-Host "  --threads: Number of threads (default: 6)"
    Write-Host ""
    Write-Host "Runs solvation calculation for paracetamol"
    Write-Host "Works with ORCA (SMD), OCC (SMD), and xTB (ALPB)"
    Write-Host ""
    Write-Host "The calculation performs:"
    Write-Host "  1. Gas phase calculation"
    Write-Host "  2. Solution phase calculation with solvation model"
    Write-Host "  3. Solvation free energy calculation"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Method/basis: Use command-line flags"
    Write-Host "  - Solvent: Use --solvent flag (water, ethanol, dmso, etc.)"
    Write-Host "  - Geometry: Modify paracetamol.xyz file"
    Write-Host ""
    Write-Host "Expected outputs:"
    Write-Host "  - Gas phase energy"
    Write-Host "  - Solution phase energy"
    Write-Host "  - Solvation free energy (ΔG_solv)"
    Write-Host ""
    Write-Host "If --program is not specified, will try orca first, then occ, then xtb"
    exit 0
}

if ($Help) {
    Show-Usage
}

function Test-Program {
    param([string]$ProgramName)
    $null = Get-Command $ProgramName -ErrorAction SilentlyContinue
    return $?
}

function Get-SelectedProgram {
    if ($Program) {
        if (!(Test-Program $Program)) {
            Write-Host "Error: Specified program '$Program' not found in PATH" -ForegroundColor Red
            exit 1
        }
        return $Program
    } else {
        if (Test-Program "orca") {
            return "orca"
        } elseif (Test-Program "occ") {
            return "occ"
        } elseif (Test-Program "xtb") {
            return "xtb"
        } else {
            Write-Host "Error: Neither 'orca', 'occ', nor 'xtb' found in PATH" -ForegroundColor Red
            exit 1
        }
    }
}

function Run-Orca {
    Write-Host "Using ORCA with method=$Method, basis=$Basis, solvent=$Solvent"
    Write-Host ""
    
    # Create ORCA input files
    $gasInput = @"
! $Method $Basis

* XYZFILE 0 1 paracetamol.xyz

"@
    if ($Threads -gt 1) {
        $gasInput += @"
%pal
nprocs $Threads
end
"@
    }
    $gasInput | Out-File -FilePath "gas.inp" -Encoding ASCII
    
    # Convert solvent name to uppercase for ORCA
    $SOLVENT_UPPER = $Solvent.ToUpper()
    $smdInput = @"
! $Method $Basis SMD($SOLVENT_UPPER)

* XYZFILE 0 1 paracetamol.xyz

"@
    if ($Threads -gt 1) {
        $smdInput += @"
%pal
nprocs $Threads
end
"@
    }
    $smdInput | Out-File -FilePath "smd.inp" -Encoding ASCII
    
    # Run gas phase calculation
    Write-Host "Running gas phase calculation..."
    $gasOutput = & orca gas.inp 2>&1 | Tee-Object -FilePath gas.stdout
    
    # Run solution phase calculation
    Write-Host ""
    Write-Host "Running solution phase calculation (SMD)..."
    $smdOutput = & orca smd.inp 2>&1 | Tee-Object -FilePath smd.stdout
    
    # Extract energies
    $E_gas = ($gasOutput | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
    $E_sol = ($smdOutput | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
    
    Analyze-Results-Orca $E_gas $E_sol
}

function Run-Occ {
    Write-Host "Using OCC with method=$Method, basis=$Basis, solvent=$Solvent"
    Write-Host ""
    
    # Run gas phase calculation
    Write-Host "Running gas phase calculation..."
    $gasOutput = & occ scf paracetamol.xyz $Method $Basis --threads=$Threads 2>&1 | Tee-Object -FilePath gas.stdout
    
    # Run solution phase calculation
    Write-Host ""
    Write-Host "Running solution phase calculation (SMD)..."
    $smdOutput = & occ scf paracetamol.xyz $Method $Basis --solvent=$Solvent --threads=$Threads 2>&1 | Tee-Object -FilePath smd.stdout
    
    # Extract energies
    $E_gas = ($gasOutput | Select-String -Pattern "^total\s+(-?\d+\.\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
    $E_sol = ($smdOutput | Select-String -Pattern "^total\s+(-?\d+\.\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
    
    Analyze-Results-Occ $E_gas $E_sol
}

function Run-Xtb {
    # Set default method for xTB if using DFT
    if ($Method -eq "b3lyp") {
        $Method = "gfn2"
    }
    
    Write-Host "Using xTB with method=$Method, solvent=$Solvent (basis set ignored)"
    Write-Host ""
    
    $env:OMP_NUM_THREADS = $Threads
    $env:OMP_STACKSIZE = "16000"
    
    # Run gas phase calculation
    Write-Host "Running gas phase calculation..."
    $gasOutput = & xtb paracetamol.xyz "--$Method" 2>&1 | Tee-Object -FilePath gas.stdout
    
    # Run solution phase calculation with ALPB
    Write-Host ""
    Write-Host "Running solution phase calculation (ALPB)..."
    $smdOutput = & xtb paracetamol.xyz "--$Method" --alpb $Solvent 2>&1 | Tee-Object -FilePath smd.stdout
    
    # Extract energies
    $E_gas = ($gasOutput | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
    $E_sol = ($smdOutput | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
    
    Analyze-Results-Xtb $E_gas $E_sol
}

function Analyze-Results-Orca {
    param($E_gas, $E_sol)
    
    # Calculate solvation free energy in hartree
    $G_solv = [double]$E_sol - [double]$E_gas
    
    # Convert to kJ/mol
    $G_solv_kjmol = $G_solv * 2625.4996
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "SOLVATION FREE ENERGY ANALYSIS" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total energies:"
    Write-Host ("  Gas phase:      {0:F6} hartree" -f [double]$E_gas)
    Write-Host ("  Solution phase: {0:F6} hartree" -f [double]$E_sol)
    Write-Host ""
    Write-Host "Solvation free energy:"
    Write-Host ("  ΔG_solv = {0:F6} hartree = {1:F2} kJ/mol" -f $G_solv, $G_solv_kjmol)
    
    # Check for SMD breakdown in ORCA output
    $smdContent = Get-Content smd.stdout -Raw
    if ($smdContent -match "Solvation") {
        Write-Host ""
        Write-Host "SMD contributions:"
        $smdLines = $smdContent -split "`n" | Where-Object { $_ -match "Electrostatic|CDS|Dispersion" } | Select-Object -First 3
        $smdLines | ForEach-Object { Write-Host "  $_" }
    }
    
    Print-Analysis $G_solv_kjmol
}

function Analyze-Results-Occ {
    param($E_gas, $E_sol)
    
    # Calculate solvation free energy in hartree
    $G_solv = [double]$E_sol - [double]$E_gas
    
    # Convert to kJ/mol
    $G_solv_kjmol = $G_solv * 2625.4996
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "SOLVATION FREE ENERGY ANALYSIS" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total energies:"
    Write-Host ("  Gas phase:      {0:F6} hartree" -f [double]$E_gas)
    Write-Host ("  Solution phase: {0:F6} hartree" -f [double]$E_sol)
    Write-Host ""
    Write-Host "Solvation free energy:"
    Write-Host ("  ΔG_solv = {0:F6} hartree = {1:F2} kJ/mol" -f $G_solv, $G_solv_kjmol)
    
    # Extract SMD contributions if available
    $smdContent = Get-Content smd.stdout -Raw
    if ($smdContent -match "SMD solvation") {
        $E_elec = if ($smdContent -match "electrostatic.*?(-?\d+\.\d+)") { [double]$matches[1] } else { $null }
        $E_cds = if ($smdContent -match "CDS.*?(-?\d+\.\d+)") { [double]$matches[1] } else { $null }
        
        if ($E_elec) {
            Write-Host ""
            Write-Host "SMD contributions:"
            Write-Host ("  Electrostatic:  {0:F2} kJ/mol" -f $E_elec)
            Write-Host ("  CDS:            {0:F2} kJ/mol" -f $E_cds)
        }
    }
    
    Print-Analysis $G_solv_kjmol
}

function Analyze-Results-Xtb {
    param($E_gas, $E_sol)
    
    # Calculate solvation free energy in hartree
    $G_solv = [double]$E_sol - [double]$E_gas
    
    # Convert to kJ/mol
    $G_solv_kjmol = $G_solv * 2625.4996
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "SOLVATION FREE ENERGY ANALYSIS" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total energies:"
    Write-Host ("  Gas phase:      {0:F6} hartree" -f [double]$E_gas)
    Write-Host ("  Solution phase: {0:F6} hartree" -f [double]$E_sol)
    Write-Host ""
    Write-Host "Solvation free energy:"
    Write-Host ("  ΔG_solv = {0:F6} hartree = {1:F2} kJ/mol" -f $G_solv, $G_solv_kjmol)
    
    Write-Host ""
    Write-Host "ALPB solvation model:"
    Write-Host "  - Analytical linearized Poisson-Boltzmann approach"
    Write-Host "  - Fast approximate continuum solvation"
    Write-Host "  - Good for screening and qualitative trends"
    
    Print-Analysis $G_solv_kjmol
}

function Print-Analysis {
    param($G_solv_kjmol)
    
    Write-Host ""
    Write-Host "Solubility analysis:"
    Write-Host "  Experimental solubility of paracetamol in water: ~15 g/L at 25°C"
    Write-Host ""
    Write-Host "  Note: ΔG_solv relates to solubility through:"
    Write-Host "  log S = (ΔG_fusion - ΔG_solv) / (2.303 RT)"
    Write-Host ""
    Write-Host "  A 5.7 kJ/mol error in ΔG corresponds to ~1 order of magnitude in solubility"
    
    # Calculate approximate log S if we have typical values
    $RT_298 = 8.314 * 298.15 / 1000  # R*T in kJ/mol
    Write-Host ""
    Write-Host ("  At 298K: RT = {0:F2} kJ/mol" -f $RT_298)
    Write-Host "  For accurate solubility: need ΔG_fusion from crystal structure"
}

Write-Host "SMD calculations completed. Results saved to gas.stdout and smd.stdout"
Write-Host ""

$SELECTED_PROGRAM = Get-SelectedProgram

switch ($SELECTED_PROGRAM) {
    "orca" { Run-Orca }
    "occ" { Run-Occ }
    "xtb" { Run-Xtb }
}