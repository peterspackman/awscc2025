# AWSCC 2025 Workshop Setup Script for Windows
# Installs OCC from GitHub releases and sets up environment

param(
    [switch]$Help
)

if ($Help) {
    Write-Host "AWSCC 2025 Workshop Setup Script"
    Write-Host "Usage: .\setup.ps1"
    Write-Host ""
    Write-Host "This script downloads and installs OCC from GitHub releases"
    Write-Host "and sets up the workshop environment."
    exit 0
}

$ErrorActionPreference = "Stop"

$WorkshopDir = Split-Path -Parent $PSScriptRoot
$BinDir = Join-Path $WorkshopDir "bin"
$DataDir = Join-Path $WorkshopDir "data"

Write-Host "=== AWSCC 2025 Workshop Setup ===" -ForegroundColor Green
Write-Host "Workshop directory: $WorkshopDir"
Write-Host "Installing OCC to: $BinDir"

# Detect architecture
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$Platform = "windows-$Arch"

Write-Host "Detected platform: $Platform"

try {
    # Get latest release info from GitHub API
    Write-Host "Fetching latest OCC release information..."
    $LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/peterspackman/occ/releases/latest"
    $Version = $LatestRelease.tag_name
    
    if (-not $Version) {
        Write-Host "Failed to get latest version. Using 'latest' tag..."
        $Version = "latest"
    }
    
    Write-Host "OCC version: $Version"
    
    # Construct download URL
    if ($Version -eq "latest") {
        $DownloadUrl = "https://github.com/peterspackman/occ/releases/latest/download/occ-$Platform.zip"
    } else {
        $DownloadUrl = "https://github.com/peterspackman/occ/releases/download/$Version/occ-$Platform.zip"
    }
    
    Write-Host "Download URL: $DownloadUrl"
    
    # Create directories
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
    
    # Download OCC
    Write-Host "Downloading OCC..."
    $ZipPath = Join-Path $WorkshopDir "occ-$Platform.zip"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath
    
    # Extract OCC
    Write-Host "Extracting OCC..."
    $ExtractPath = Join-Path $WorkshopDir "occ_temp"
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
    
    # Find and move files
    $OccExe = Get-ChildItem -Path $ExtractPath -Name "occ.exe" -Recurse | Select-Object -First 1
    if ($OccExe) {
        $OccPath = Join-Path $ExtractPath $OccExe
        Copy-Item $OccPath -Destination $BinDir
        Write-Host "OCC binary copied to $BinDir"
    } else {
        throw "Could not find occ.exe in extracted files"
    }
    
    # Look for data files
    $ShareDir = Get-ChildItem -Path $ExtractPath -Name "share" -Recurse -Directory | Select-Object -First 1
    if ($ShareDir) {
        $SharePath = Join-Path $ExtractPath $ShareDir
        Copy-Item $SharePath -Destination $DataDir -Recurse -Force
        Write-Host "Data files copied to $DataDir"
    }
    
    # Clean up
    Remove-Item $ZipPath -Force
    Remove-Item $ExtractPath -Recurse -Force
    
    # Create environment setup script
    $SetupEnvContent = @"
# Source this file to set up the workshop environment
# Usage: . .\setup_env.ps1

`$WorkshopDir = Split-Path -Parent `$PSCommandPath
`$env:PATH = "`$(Join-Path `$WorkshopDir 'bin');`$env:PATH"

# Set OCC data path if data directory exists
`$DataShareDir = Join-Path `$WorkshopDir "data\share"
`$DataDir = Join-Path `$WorkshopDir "data"

if (Test-Path `$DataShareDir) {
    `$env:OCC_DATA_PATH = `$DataShareDir
} elseif (Test-Path `$DataDir) {
    `$env:OCC_DATA_PATH = `$DataDir
}

Write-Host "Workshop environment set up:"
Write-Host "  OCC binary: `$(Get-Command occ -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)"
Write-Host "  OCC data path: `$(`$env:OCC_DATA_PATH)"
"@
    
    Set-Content -Path (Join-Path $WorkshopDir "setup_env.ps1") -Value $SetupEnvContent
    
    # Test installation
    Write-Host ""
    Write-Host "Testing OCC installation..."
    $env:PATH = "$BinDir;$env:PATH"
    
    $DataShareDir = Join-Path $DataDir "share"
    if (Test-Path $DataShareDir) {
        $env:OCC_DATA_PATH = $DataShareDir
    } elseif (Test-Path $DataDir) {
        $env:OCC_DATA_PATH = $DataDir
    }
    
    $OccBinary = Join-Path $BinDir "occ.exe"
    if (Test-Path $OccBinary) {
        try {
            & $OccBinary --help | Out-Null
            Write-Host "✅ OCC installation successful!" -ForegroundColor Green
            Write-Host ""
            Write-Host "To use OCC in your PowerShell session, run:"
            Write-Host "  . .\setup_env.ps1" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "OCC version information:"
            & $OccBinary --help | Select-Object -First 5
        } catch {
            throw "OCC binary test failed: $_"
        }
    } else {
        throw "OCC binary not found at $OccBinary"
    }
    
    Write-Host ""
    Write-Host "=== Setup Complete ===" -ForegroundColor Green
    Write-Host "Next steps:"
    Write-Host "1. Run: . .\setup_env.ps1"
    Write-Host "2. Test: occ --help"
    Write-Host "3. Start workshop: see examples\ directory"
    
} catch {
    Write-Host "❌ Setup failed: $_" -ForegroundColor Red
    Write-Host "Please check your internet connection and try again."
    Write-Host "If the problem persists, try installing OCC manually from:"
    Write-Host "https://github.com/peterspackman/occ/releases"
    exit 1
}