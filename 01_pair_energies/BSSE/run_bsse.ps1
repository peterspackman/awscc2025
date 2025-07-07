param(
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host "Usage: .\$($MyInvocation.MyCommand.Name) [--help]"
    Write-Host ""
    Write-Host "Runs ORCA BSSE calculation using bsse.inp file"
    Write-Host "This script only works with ORCA"
    Write-Host ""
    Write-Host "To customize the calculation:"
    Write-Host "  - Method/basis: Edit the '! wb97x def2-qzvp' lines in bsse.inp"
    Write-Host "  - Geometry: Modify the coordinate blocks in bsse.inp"
    Write-Host "  - Other settings: Add ORCA keywords/blocks to bsse.inp"
    Write-Host ""
    Write-Host "The input file contains multiple jobs for BSSE correction:"
    Write-Host "  1. Monomer A alone"
    Write-Host "  2. Monomer B alone"
    Write-Host "  3. Dimer AB"
    Write-Host "  4. Monomer A with ghost atoms of B"
    Write-Host "  5. Monomer B with ghost atoms of A"
    exit 0
}

if ($Help) {
    Show-Usage
}

if (!(Get-Command orca -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ORCA not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Running ORCA BSSE calculation..."
$output = & orca bsse.inp 2>&1 | Tee-Object -FilePath bsse.stdout

Write-Host ""
Write-Host "BSSE calculation completed. Results saved to bsse.stdout"
Write-Host ""

# Extract energies from ORCA output
Write-Host "Extracting energies from BSSE calculation..."

# Check if the output file exists and has content
if (!(Test-Path bsse.stdout) -or (Get-Item bsse.stdout).Length -eq 0) {
    Write-Host "Error: bsse.stdout is empty or does not exist" -ForegroundColor Red
    exit 1
}

$content = Get-Content bsse.stdout -Raw

# Try different patterns to extract energies
# First try the summary section pattern
$E_mon1 = if ($content -match "Energy for.*monomer from job 1.*?(-?\d+\.\d+)") { $matches[1] } else { $null }
$E_mon2 = if ($content -match "Energy for.*monomer from job 2.*?(-?\d+\.\d+)") { $matches[1] } else { $null }
$E_dimer = if ($content -match "Energy for.*dimer from job 3.*?(-?\d+\.\d+)") { $matches[1] } else { $null }
$E_mon1_ghost = if ($content -match "Energy for.*monomer_ghost from job 4.*?(-?\d+\.\d+)") { $matches[1] } else { $null }
$E_mon2_ghost = if ($content -match "Energy for.*monomer_ghost from job 5.*?(-?\d+\.\d+)") { $matches[1] } else { $null }

# If that fails, try extracting from FINAL SINGLE POINT ENERGY lines
if (!$E_mon1 -or !$E_mon2 -or !$E_dimer -or !$E_mon1_ghost -or !$E_mon2_ghost) {
    Write-Host "Summary energies not found, extracting from individual job outputs..."
    
    # Extract all FINAL SINGLE POINT ENERGY lines in order
    $energies = @()
    $matches = [regex]::Matches($content, "FINAL SINGLE POINT ENERGY\s+(-?\d+\.\d+)")
    foreach ($match in $matches) {
        $energies += $match.Groups[1].Value
    }
    
    if ($energies.Count -ge 5) {
        $E_mon1 = $energies[0]
        $E_mon2 = $energies[1]
        $E_dimer = $energies[2]
        $E_mon1_ghost = $energies[3]
        $E_mon2_ghost = $energies[4]
    } else {
        Write-Host "Error: Could not extract all 5 energies from output" -ForegroundColor Red
        Write-Host "Found $($energies.Count) energies, need 5"
        Write-Host "Please check bsse.stdout for calculation errors"
        exit 1
    }
}

# Verify all energies were extracted successfully
if (!$E_mon1 -or !$E_mon2 -or !$E_dimer -or !$E_mon1_ghost -or !$E_mon2_ghost) {
    Write-Host "Error: Failed to extract energies from output" -ForegroundColor Red
    Write-Host "Please check the bsse.stdout file for calculation errors"
    exit 1
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "BSSE CORRECTION ANALYSIS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Individual job energies:"
Write-Host ("  Monomer A:           {0:F9} hartree" -f [double]$E_mon1)
Write-Host ("  Monomer B:           {0:F9} hartree" -f [double]$E_mon2)
Write-Host ("  Dimer AB:            {0:F9} hartree" -f [double]$E_dimer)
Write-Host ("  Monomer A + ghost B: {0:F9} hartree" -f [double]$E_mon1_ghost)
Write-Host ("  Monomer B + ghost A: {0:F9} hartree" -f [double]$E_mon2_ghost)

# Calculate interaction energies
$E_int_uncorrected = [double]$E_dimer - [double]$E_mon1 - [double]$E_mon2
$E_int_corrected = [double]$E_dimer - [double]$E_mon1_ghost - [double]$E_mon2_ghost
$BSSE = $E_int_uncorrected - $E_int_corrected

# Convert to kJ/mol
$E_int_uncorrected_kjmol = $E_int_uncorrected * 2625.4996
$E_int_corrected_kjmol = $E_int_corrected * 2625.4996
$BSSE_kjmol = $BSSE * 2625.4996

Write-Host ""
Write-Host "Interaction energies:"
Write-Host ("  Uncorrected:    {0:F6} hartree = {1,7:F2} kJ/mol" -f $E_int_uncorrected, $E_int_uncorrected_kjmol)
Write-Host ("  BSSE-corrected: {0:F6} hartree = {1,7:F2} kJ/mol" -f $E_int_corrected, $E_int_corrected_kjmol)

Write-Host ""
Write-Host "BSSE correction:"
Write-Host ("  BSSE = {0:F6} hartree = {1,7:F2} kJ/mol" -f $BSSE, $BSSE_kjmol)
if ($E_int_uncorrected -ne 0) {
    $BSSE_percent = ($BSSE / $E_int_uncorrected) * 100
    Write-Host ("  BSSE = {0:F1}% of uncorrected interaction energy" -f $BSSE_percent)
}

Write-Host ""
Write-Host "Analysis:"
if ($BSSE_kjmol -gt 2.0) {
    Write-Host "  - Significant BSSE (>2 kJ/mol) - correction is important"
} elseif ($BSSE_kjmol -gt 1.0) {
    Write-Host "  - Moderate BSSE (1-2 kJ/mol) - correction recommended"
} else {
    Write-Host "  - Small BSSE (<1 kJ/mol) - correction less critical"
}

Write-Host "  - Use BSSE-corrected value for publication"
Write-Host "  - BSSE decreases with larger basis sets"