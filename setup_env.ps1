# Source this file to set up the workshop environment
# Usage: . .\setup_env.ps1

$WORKSHOP_DIR = Split-Path $PSScriptRoot -Resolve
$env:PATH = "$WORKSHOP_DIR\bin;$env:PATH"

# Set OCC data path if share directory exists
if (Test-Path "$WORKSHOP_DIR\share\occ") {
    $env:OCC_DATA_PATH = "$WORKSHOP_DIR\share\occ"
}

Write-Host "Workshop environment set up:"
$occPath = Get-Command occ -ErrorAction SilentlyContinue
if ($occPath) {
    Write-Host "  OCC binary: $($occPath.Source)" -ForegroundColor Green
} else {
    Write-Host "  OCC binary: NOT FOUND" -ForegroundColor Red
}
Write-Host "  OCC data path: $(if ($env:OCC_DATA_PATH) { $env:OCC_DATA_PATH } else { 'NOT SET' })"