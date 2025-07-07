param(
    [string]$Program = "",
    [string]$Method = "hf",
    [string]$Basis = "3-21g",
    [int]$Threads = 1,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--program orca|occ] [--method METHOD] [--basis BASIS] [--threads N]"
    Write-Host "  --program: Specify quantum chemistry program (orca or occ)"
    Write-Host "  --method:  Quantum chemistry method (default: hf)"
    Write-Host "  --basis:   Basis set (default: 3-21g)"
    Write-Host "  --threads: Number of threads (default: 1)"
    Write-Host ""
    Write-Host "If --program is not specified, will try orca first, then occ"
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
        } else {
            Write-Host "Error: Neither 'orca' nor 'occ' found in PATH" -ForegroundColor Red
            exit 1
        }
    }
}

function Run-Orca {
    Write-Host "Using ORCA"
    
    if ($Method -ne "hf" -or $Basis -ne "3-21g") {
        Write-Host "Warning: ORCA uses input files (A.inp, B.inp, AB.inp) with predefined method/basis." -ForegroundColor Yellow
        Write-Host "         The --method and --basis arguments are ignored for ORCA." -ForegroundColor Yellow
        Write-Host "         To use different settings, manually edit the .inp files." -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host -NoNewline "A: "
    $outputA = & orca A.inp 2>&1 | Tee-Object -FilePath A.stdout
    $E_A = ($outputA | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
    
    Write-Host -NoNewline "B: "
    $outputB = & orca B.inp 2>&1 | Tee-Object -FilePath B.stdout
    $E_B = ($outputB | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value
    
    Write-Host -NoNewline "AB: "
    $outputAB = & orca AB.inp 2>&1 | Tee-Object -FilePath AB.stdout
    $E_AB = ($outputAB | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value

    Write-Host "total A                               $E_A"
    Write-Host "total B                               $E_B"
    Write-Host "total AB                              $E_AB"
    
    # Calculate interaction energy in hartree
    $E_int = [double]$E_AB - [double]$E_A - [double]$E_B
    
    # Convert to kJ/mol (1 hartree = 2625.4996 kJ/mol)
    $E_int_kjmol = $E_int * 2625.4996
    
    Write-Host ""
    Write-Host "Interaction Energy:"
    Write-Host ("  ΔE = {0:F9} hartree" -f $E_int)
    Write-Host ("  ΔE = {0:F2} kJ/mol" -f $E_int_kjmol)
}

function Run-Occ {
    Write-Host "Using OCC"
    
    Write-Host -NoNewline "A: "
    $outputA = & occ scf A.xyz --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath A.stdout
    $E_A = ($outputA | Select-String -Pattern "^total\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value

    Write-Host -NoNewline "B: "  
    $outputB = & occ scf B.xyz --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath B.stdout
    $E_B = ($outputB | Select-String -Pattern "^total\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value

    Write-Host -NoNewline "AB: "
    $outputAB = & occ scf AB.xyz --threads=$Threads $Method $Basis 2>&1 | Tee-Object -FilePath AB.stdout
    $E_AB = ($outputAB | Select-String -Pattern "^total\s+(-?\d+\.\d+)").Matches[0].Groups[1].Value

    Write-Host "total A                               $E_A"
    Write-Host "total B                               $E_B"
    Write-Host "total AB                              $E_AB"

    # Calculate interaction energy in hartree
    $E_int = [double]$E_AB - [double]$E_A - [double]$E_B

    # Convert to kJ/mol (1 hartree = 2625.4996 kJ/mol)
    $E_int_kjmol = $E_int * 2625.4996

    Write-Host ""
    Write-Host "Interaction Energy:"
    Write-Host ("  ΔE = {0:F9} hartree" -f $E_int)
    Write-Host ("  ΔE = {0:F2} kJ/mol" -f $E_int_kjmol)
}

$SELECTED_PROGRAM = Get-SelectedProgram

switch ($SELECTED_PROGRAM) {
    "orca" { Run-Orca }
    "occ" { Run-Occ }
}