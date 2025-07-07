param(
    [string]$Program = "",
    [string]$Method = "hf",
    [string]$Basis = "3-21g",
    [int]$Threads = 1,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--program orca|occ|xtb] [--method METHOD] [--basis BASIS] [--threads N] [--help]"
    Write-Host "  --program: Specify quantum chemistry program (orca, occ, or xtb)"
    Write-Host "  --method:  Quantum chemistry method (default: hf)"
    Write-Host "             For xTB: gfn1, gfn2, gfnff (default: gfn2)"
    Write-Host "  --basis:   Basis set (default: 3-21g) - ignored for xTB"
    Write-Host "  --threads: Number of threads (default: 1)"
    Write-Host ""
    Write-Host "Calculates water trimer interaction energy and compares:"
    Write-Host "  1. Direct trimer calculation: E_ABC - E_A - E_B - E_C"
    Write-Host "  2. Sum of pairwise interactions: E_AB + E_AC + E_BC - 2*(E_A + E_B + E_C)"
    Write-Host ""
    Write-Host "This shows many-body effects vs pairwise approximation"
    Write-Host ""
    Write-Host "If --program is not specified, will try orca first, then occ, then xtb"
    exit 1
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
    Write-Host "Using ORCA with method=$Method, basis=$Basis"
    Write-Host ""
    
    # Create input files for ORCA
    foreach ($mol in @("A", "B", "C", "AB", "AC", "BC", "ABC")) {
        @"
! $Method $Basis
*xyzfile 0 1 ${mol}.xyz

"@ | Out-File -FilePath "${mol}.inp" -Encoding ASCII
    }
    
    # Run calculations
    Write-Host "Running monomer calculations..."
    $energies = @{}
    foreach ($mol in @("A", "B", "C")) {
        Write-Host "  ${mol}:"
        $output = & orca "${mol}.inp" 2>&1 | Tee-Object -FilePath "${mol}.stdout"
        $E_MOL = ($output | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
        $energies[$mol] = [double]$E_MOL
        Write-Host "    Energy: $E_MOL"
    }
    
    Write-Host ""
    Write-Host "Running dimer calculations..."
    foreach ($mol in @("AB", "AC", "BC")) {
        Write-Host "  ${mol}:"
        $output = & orca "${mol}.inp" 2>&1 | Tee-Object -FilePath "${mol}.stdout"
        $E_MOL = ($output | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
        $energies[$mol] = [double]$E_MOL
        Write-Host "    Energy: $E_MOL"
    }
    
    Write-Host ""
    Write-Host "Running trimer calculation..."
    Write-Host "  ABC:"
    $output = & orca "ABC.inp" 2>&1 | Tee-Object -FilePath "ABC.stdout"
    $E_ABC = ($output | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
    $energies["ABC"] = [double]$E_ABC
    Write-Host "    Energy: $E_ABC"
    
    Analyze-Results $energies
}

function Run-Occ {
    Write-Host "Using OCC with method=$Method, basis=$Basis"
    Write-Host ""
    
    Write-Host "Running monomer calculations..."
    $energies = @{}
    foreach ($mol in @("A", "B", "C")) {
        Write-Host "  ${mol}:"
        $output = & occ scf "${mol}.xyz" --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath "${mol}.stdout"
        $E_MOL = ($output | Select-String -Pattern "^total\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
        $energies[$mol] = [double]$E_MOL
        Write-Host "    Energy: $E_MOL"
    }
    
    Write-Host ""
    Write-Host "Running dimer calculations..."
    foreach ($mol in @("AB", "AC", "BC")) {
        Write-Host "  ${mol}:"
        $output = & occ scf "${mol}.xyz" --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath "${mol}.stdout"
        $E_MOL = ($output | Select-String -Pattern "^total\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
        $energies[$mol] = [double]$E_MOL
        Write-Host "    Energy: $E_MOL"
    }
    
    Write-Host ""
    Write-Host "Running trimer calculation..."
    Write-Host "  ABC:"
    $output = & occ scf "ABC.xyz" --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath "ABC.stdout"
    $E_ABC = ($output | Select-String -Pattern "^total\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
    $energies["ABC"] = [double]$E_ABC
    Write-Host "    Energy: $E_ABC"
    
    Analyze-Results $energies
}

function Run-Xtb {
    # Set default method for xTB if using HF
    if ($Method -eq "hf") {
        $Method = "gfn2"
    }
    
    Write-Host "Using xTB with method=$Method (basis set ignored)"
    Write-Host ""
    
    $env:OMP_NUM_THREADS = $Threads
    $env:OMP_STACKSIZE = "16000"
    
    Write-Host "Running monomer calculations..."
    $energies = @{}
    foreach ($mol in @("A", "B", "C")) {
        Write-Host "  ${mol}:"
        $output = & xtb "${mol}.xyz" "--$Method" 2>&1 | Tee-Object -FilePath "${mol}.stdout"
        $E_MOL = ($output | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
        $energies[$mol] = [double]$E_MOL
        Write-Host "    Energy: $E_MOL"
    }
    
    Write-Host ""
    Write-Host "Running dimer calculations..."
    foreach ($mol in @("AB", "AC", "BC")) {
        Write-Host "  ${mol}:"
        $output = & xtb "${mol}.xyz" "--$Method" 2>&1 | Tee-Object -FilePath "${mol}.stdout"
        $E_MOL = ($output | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
        $energies[$mol] = [double]$E_MOL
        Write-Host "    Energy: $E_MOL"
    }
    
    Write-Host ""
    Write-Host "Running trimer calculation..."
    Write-Host "  ABC:"
    $output = & xtb "ABC.xyz" "--$Method" 2>&1 | Tee-Object -FilePath "ABC.stdout"
    $E_ABC = ($output | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)" | Select-Object -Last 1).Matches[0].Groups[1].Value
    $energies["ABC"] = [double]$E_ABC
    Write-Host "    Energy: $E_ABC"
    
    Analyze-Results $energies
}

function Analyze-Results {
    param($energies)
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "INTERACTION ENERGY ANALYSIS" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    
    # Calculate pairwise interaction energies
    $E_int_AB = $energies["AB"] - $energies["A"] - $energies["B"]
    $E_int_AC = $energies["AC"] - $energies["A"] - $energies["C"]
    $E_int_BC = $energies["BC"] - $energies["B"] - $energies["C"]
    
    # Calculate direct trimer interaction energy
    $E_int_trimer = $energies["ABC"] - $energies["A"] - $energies["B"] - $energies["C"]
    
    # Calculate sum of pairwise interactions
    $E_int_pairwise = $E_int_AB + $E_int_AC + $E_int_BC
    
    # Calculate many-body contribution
    $E_many_body = $E_int_trimer - $E_int_pairwise
    
    # Convert to kJ/mol
    $hartree_to_kjmol = 2625.4996
    $E_int_AB_kjmol = $E_int_AB * $hartree_to_kjmol
    $E_int_AC_kjmol = $E_int_AC * $hartree_to_kjmol
    $E_int_BC_kjmol = $E_int_BC * $hartree_to_kjmol
    $E_int_trimer_kjmol = $E_int_trimer * $hartree_to_kjmol
    $E_int_pairwise_kjmol = $E_int_pairwise * $hartree_to_kjmol
    $E_many_body_kjmol = $E_many_body * $hartree_to_kjmol
    
    Write-Host ""
    Write-Host "Individual pairwise interactions:"
    Write-Host ("  E_int(A-B) = {0:F6} hartree = {1:F2} kJ/mol" -f $E_int_AB, $E_int_AB_kjmol)
    Write-Host ("  E_int(A-C) = {0:F6} hartree = {1:F2} kJ/mol" -f $E_int_AC, $E_int_AC_kjmol)
    Write-Host ("  E_int(B-C) = {0:F6} hartree = {1:F2} kJ/mol" -f $E_int_BC, $E_int_BC_kjmol)
    
    Write-Host ""
    Write-Host "Trimer interaction energies:"
    Write-Host ("  Direct trimer:     {0:F6} hartree = {1:F2} kJ/mol" -f $E_int_trimer, $E_int_trimer_kjmol)
    Write-Host ("  Sum of pairs:      {0:F6} hartree = {1:F2} kJ/mol" -f $E_int_pairwise, $E_int_pairwise_kjmol)
    Write-Host ("  Many-body effect:  {0:F6} hartree = {1:F2} kJ/mol" -f $E_many_body, $E_many_body_kjmol)
    
    Write-Host ""
    if ($E_int_trimer -ne 0) {
        $many_body_percent = ($E_many_body / $E_int_trimer) * 100
        Write-Host ("Many-body contribution: {0:F1}% of total interaction" -f $many_body_percent)
    }
}

$SELECTED_PROGRAM = Get-SelectedProgram

switch ($SELECTED_PROGRAM) {
    "orca" { Run-Orca }
    "occ" { Run-Occ }
    "xtb" { Run-Xtb }
}