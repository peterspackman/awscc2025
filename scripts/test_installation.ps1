# Test script for AWSCC 2025 workshop installation
# Verifies that all required software is working correctly

$ErrorActionPreference = "Stop"

$WORKSHOP_DIR = Split-Path (Split-Path $PSScriptRoot -Parent) -Resolve
Set-Location $WORKSHOP_DIR

Write-Host "=== AWSCC 2025 Installation Test ===" -ForegroundColor Cyan
Write-Host "Workshop directory: $WORKSHOP_DIR"
Write-Host ""

# Test function
function Test-Command {
    param(
        [string]$Name,
        [string]$Command,
        [string]$ExpectedPattern = ""
    )
    
    Write-Host -NoNewline "Testing $Name... "
    
    try {
        $output = Invoke-Expression $Command 2>&1 | Out-String
        
        if ([string]::IsNullOrEmpty($ExpectedPattern) -or $output -match $ExpectedPattern) {
            Write-Host "✓" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ (unexpected output)" -ForegroundColor Red
            Write-Host "Expected pattern: $ExpectedPattern"
            Write-Host "Got: $output"
            return $false
        }
    } catch {
        Write-Host "✗ (command failed)" -ForegroundColor Red
        Write-Host "Error: $_"
        return $false
    }
}

# Source environment if available
if (Test-Path "setup_env.ps1") {
    Write-Host "Loading workshop environment..." -ForegroundColor Yellow
    . .\setup_env.ps1
    Write-Host ""
}

# Test OCC
Write-Host "=== Testing OCC ===" -ForegroundColor Cyan

if (Test-Path "geometries\water.xyz") {
    Write-Host ""
    Write-Host "=== Testing OCC calculation ===" -ForegroundColor Cyan
    Write-Host -NoNewline "Testing OCC SCF on water... "
    
    $TEMP_DIR = New-TemporaryFile | %{ mkdir $_.FullName.Replace('.tmp', '') -Force }
    Copy-Item "geometries\water.xyz" -Destination $TEMP_DIR.FullName
    
    try {
        Push-Location $TEMP_DIR.FullName
        $output = & occ scf water.xyz rhf 3-21g 2>&1 | Out-String
        
        # Extract energy from output
        $energyMatch = $output | Select-String -Pattern "^total\s+(-?\d+\.\d+)" 
        if ($energyMatch) {
            $ENERGY = $energyMatch.Matches[0].Groups[1].Value
            Write-Host "✓ (E = $ENERGY hartree)" -ForegroundColor Green
        } else {
            Write-Host "⚠ (completed but no energy found)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗" -ForegroundColor Red
    } finally {
        Pop-Location
        Remove-Item -Path $TEMP_DIR.FullName -Recurse -Force
    }
}

Write-Host ""

# Test optional software
Write-Host "=== Testing Optional Software ===" -ForegroundColor Cyan

# XTB
$xtbPath = Get-Command xtb -ErrorAction SilentlyContinue
if ($xtbPath) {
    Write-Host -NoNewline "Testing XTB calculation... "
    
    $TEMP_DIR = New-TemporaryFile | %{ mkdir $_.FullName.Replace('.tmp', '') -Force }
    Copy-Item "geometries\water.xyz" -Destination $TEMP_DIR.FullName
    
    try {
        Push-Location $TEMP_DIR.FullName
        $output = & xtb water.xyz --sp 2>&1 | Out-String
        
        # Extract energy from output
        $energyMatch = $output | Select-String -Pattern "TOTAL ENERGY\s+(-?\d+\.\d+)"
        if ($energyMatch) {
            $ENERGY = $energyMatch.Matches[0].Groups[1].Value
            Write-Host "✓ (E = $ENERGY hartree)" -ForegroundColor Green
        } else {
            Write-Host "⚠ (completed but no energy found)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗" -ForegroundColor Red
    } finally {
        Pop-Location
        Remove-Item -Path $TEMP_DIR.FullName -Recurse -Force
    }
} else {
    Write-Host "XTB not found (optional)" -ForegroundColor Yellow
}

# ORCA
$orcaPath = Get-Command orca -ErrorAction SilentlyContinue
if ($orcaPath) {
    Write-Host -NoNewline "Testing ORCA calculation... "
    
    $TEMP_DIR = New-TemporaryFile | %{ mkdir $_.FullName.Replace('.tmp', '') -Force }
    $orcaInput = @"
! HF 3-21G
* xyz 0 1
O 0.0 0.0 0.0
H -0.757 0.586 0.0
H 0.757 0.586 0.0
*
"@
    $orcaInput | Out-File -FilePath "$($TEMP_DIR.FullName)\orca_test.inp" -Encoding ASCII
    
    try {
        Push-Location $TEMP_DIR.FullName
        $output = & orca orca_test.inp 2>&1 | Out-String
        
        # Extract energy from output
        $outputContent = Get-Content "orca_test.out" -ErrorAction SilentlyContinue | Out-String
        $energyMatch = $outputContent | Select-String -Pattern "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)"
        if ($energyMatch) {
            $ENERGY = $energyMatch.Matches[0].Groups[1].Value
            Write-Host "✓ (E = $ENERGY hartree)" -ForegroundColor Green
        } else {
            # Check if it at least started
            if ($outputContent -match "ORCA") {
                Write-Host "⚠ (found but may need license/setup)" -ForegroundColor Yellow
            } else {
                Write-Host "✗" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "✗" -ForegroundColor Red
    } finally {
        Pop-Location
        Remove-Item -Path $TEMP_DIR.FullName -Recurse -Force
    }
} else {
    Write-Host "ORCA not found (optional)" -ForegroundColor Yellow
}

# Gaussian
$GAUSSIAN_CMD = ""
if (Get-Command g16 -ErrorAction SilentlyContinue) {
    $GAUSSIAN_CMD = "g16"
} elseif (Get-Command g09 -ErrorAction SilentlyContinue) {
    $GAUSSIAN_CMD = "g09"
}

if ($GAUSSIAN_CMD) {
    Write-Host -NoNewline "Testing Gaussian calculation... "
    
    $TEMP_DIR = New-TemporaryFile | %{ mkdir $_.FullName.Replace('.tmp', '') -Force }
    $gaussianInput = @"
# HF/3-21G

Water molecule test

0 1
O 0.0 0.0 0.0
H -0.757 0.586 0.0
H 0.757 0.586 0.0

"@
    $gaussianInput | Out-File -FilePath "$($TEMP_DIR.FullName)\gaussian_test.gjf" -Encoding ASCII
    
    try {
        Push-Location $TEMP_DIR.FullName
        $output = & $GAUSSIAN_CMD gaussian_test.gjf 2>&1 | Out-String
        
        # Extract energy from output
        $logContent = Get-Content "gaussian_test.log" -ErrorAction SilentlyContinue | Out-String
        $energyMatch = $logContent | Select-String -Pattern "SCF Done:.*=\s+(-?\d+\.\d+)" | Select-Object -Last 1
        if ($energyMatch) {
            $ENERGY = $energyMatch.Matches[0].Groups[1].Value
            Write-Host "✓ (E = $ENERGY hartree)" -ForegroundColor Green
        } else {
            Write-Host "⚠ (completed but no energy found)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗" -ForegroundColor Red
    } finally {
        Pop-Location
        Remove-Item -Path $TEMP_DIR.FullName -Recurse -Force
    }
} else {
    Write-Host "Gaussian not found (optional)" -ForegroundColor Yellow
}

# Psi4
$psi4Path = Get-Command psi4 -ErrorAction SilentlyContinue
if ($psi4Path) {
    Write-Host -NoNewline "Testing Psi4 calculation... "
    
    $TEMP_DIR = New-TemporaryFile | %{ mkdir $_.FullName.Replace('.tmp', '') -Force }
    $psi4Input = @"
import psi4

psi4.set_output_file("psi4_output.txt", False)

molecule = psi4.geometry("""
0 1
O 0.0 0.0 0.0
H -0.757 0.586 0.0
H 0.757 0.586 0.0
""")

energy = psi4.energy('hf/3-21g')
print(f"ENERGY: {energy}")
"@
    $psi4Input | Out-File -FilePath "$($TEMP_DIR.FullName)\psi4_test.py" -Encoding UTF8
    
    try {
        Push-Location $TEMP_DIR.FullName
        $output = python3 psi4_test.py 2>&1 | Out-String
        
        # Extract energy from output
        $energyMatch = $output | Select-String -Pattern "ENERGY:\s+(-?\d+\.\d+)"
        if ($energyMatch) {
            $ENERGY = $energyMatch.Matches[0].Groups[1].Value
            Write-Host "✓ (E = $ENERGY hartree)" -ForegroundColor Green
        } else {
            Write-Host "⚠ (completed but no energy found)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗" -ForegroundColor Red
    } finally {
        Pop-Location
        Remove-Item -Path $TEMP_DIR.FullName -Recurse -Force
    }
} else {
    Write-Host "Psi4 not found (optional)" -ForegroundColor Yellow
}

Write-Host ""

# Test Python and tools
Write-Host "=== Testing Python Tools ===" -ForegroundColor Cyan

if (Get-Command python3 -ErrorAction SilentlyContinue) {
    Test-Command -Name "Python 3" -Command "python3 --version" -ExpectedPattern "Python 3"
} else {
    Write-Host "Python 3 not found" -ForegroundColor Yellow
}

if (Get-Command uv -ErrorAction SilentlyContinue) {
    Test-Command -Name "UV tool" -Command "uv --version"
} else {
    Write-Host "UV not found" -ForegroundColor Yellow
}

Write-Host ""

# Test file structure
Write-Host "=== Testing Workshop Files ===" -ForegroundColor Cyan

$test_files = @(
    "geometries\paracetamol.cif",
    "geometries\urea.cif",
    "geometries\ice.cif",
    "geometries\water.xyz",
    "geometries\benzene.xyz",
    "geometries\methane.xyz",
    "geometries\water_dimer.xyz"
)

foreach ($file in $test_files) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file missing" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Ready to start the workshop? Check out geometries\ directory!"