# AWSCC 2025 Workshop Setup Script
# Installs OCC from GitHub releases and sets up environment

$ErrorActionPreference = "Stop"

$WORKSHOP_DIR = Split-Path (Split-Path $PSScriptRoot -Parent) -Resolve
$BIN_DIR = Join-Path $WORKSHOP_DIR "bin"

Write-Host "=== AWSCC 2025 Workshop Setup ===" -ForegroundColor Cyan
Write-Host "Workshop directory: $WORKSHOP_DIR"
Write-Host "Installing OCC to: $BIN_DIR"

# Detect architecture
$ARCH = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# For Windows, we'll use the Windows binaries
$PLATFORM_SUFFIX = "windows-x86_64"

Write-Host "Detected platform: $PLATFORM_SUFFIX"

# Get latest release info from GitHub API
Write-Host "Fetching latest OCC release information..."
try {
    $LATEST_RELEASE = Invoke-RestMethod -Uri "https://api.github.com/repos/peterspackman/occ/releases/latest" -TimeoutSec 30
    $VERSION = $LATEST_RELEASE.tag_name
} catch {
    Write-Host "Failed to get latest version from GitHub API. Using fallback version..." -ForegroundColor Yellow
    $VERSION = "v0.7.6"
    Write-Host "Using fallback OCC version: $VERSION" -ForegroundColor Yellow
}

if ([string]::IsNullOrEmpty($VERSION)) {
    Write-Host "Failed to get version information. Using fallback version..." -ForegroundColor Yellow
    $VERSION = "v0.7.6"
    Write-Host "Using fallback OCC version: $VERSION" -ForegroundColor Yellow
}

# Remove 'v' prefix from version if present
$VERSION_NUM = $VERSION -replace '^v', ''

Write-Host "OCC version: $VERSION"

# Construct download URL using actual format
$ARCHIVE_NAME = "occ-${VERSION_NUM}-${PLATFORM_SUFFIX}.zip"
$DOWNLOAD_URL = "https://github.com/peterspackman/occ/releases/download/${VERSION}/${ARCHIVE_NAME}"

Write-Host "Download URL: $DOWNLOAD_URL"

# Create directories
if (!(Test-Path $BIN_DIR)) {
    New-Item -ItemType Directory -Path $BIN_DIR -Force | Out-Null
}

# Check if OCC is already installed
if (Test-Path (Join-Path $BIN_DIR "occ.exe")) {
    Write-Host "OCC already installed in $BIN_DIR, skipping download..."
} else {
    # Download and extract OCC
    Write-Host "Downloading OCC..."
    $ARCHIVE_PATH = Join-Path $WORKSHOP_DIR $ARCHIVE_NAME
    
    try {
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ARCHIVE_PATH -TimeoutSec 300
        Write-Host "Download completed. File size: $((Get-Item $ARCHIVE_PATH).Length / 1MB) MB"
    } catch {
        Write-Host "Failed to download OCC from $DOWNLOAD_URL" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    Write-Host "Extracting OCC..."
    try {
        Expand-Archive -Path $ARCHIVE_PATH -DestinationPath $WORKSHOP_DIR -Force
        Write-Host "Extraction completed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to extract OCC archive" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    # Find the extracted files and move them appropriately
    $EXTRACTED_DIR = Join-Path $WORKSHOP_DIR "occ-${VERSION_NUM}-${PLATFORM_SUFFIX}"

    if (Test-Path $EXTRACTED_DIR) {
        Write-Host "Found extracted directory: $EXTRACTED_DIR"
        
        # Copy the executable
        $OCC_EXE = Join-Path $EXTRACTED_DIR "bin\occ.exe"
        if (Test-Path $OCC_EXE) {
            Copy-Item $OCC_EXE -Destination $BIN_DIR -Force
            Write-Host "Copied OCC executable"
        } else {
            Write-Host "Error: Could not find occ.exe in $EXTRACTED_DIR\bin\" -ForegroundColor Red
            exit 1
        }
        
        # Copy data files if they exist
        $SHARE_DIR = Join-Path $EXTRACTED_DIR "share"
        if (Test-Path $SHARE_DIR) {
            Copy-Item -Path $SHARE_DIR -Destination $WORKSHOP_DIR -Recurse -Force
            Write-Host "Copied OCC data files"
        }
        
        # Clean up extracted directory
        Remove-Item -Path $EXTRACTED_DIR -Recurse -Force
    } else {
        Write-Host "Error: Could not find extracted directory $EXTRACTED_DIR" -ForegroundColor Red
        exit 1
    }

    # Clean up
    Remove-Item -Path $ARCHIVE_PATH -Force
}

# Check if XTB is already installed
if (Test-Path (Join-Path $BIN_DIR "xtb.exe")) {
    Write-Host "XTB already installed in $BIN_DIR, skipping download..."
} else {
    # Download XTB
    Write-Host ""
    Write-Host "Downloading XTB..."

    # Get latest XTB release
    try {
        $XTB_RELEASE = Invoke-RestMethod -Uri "https://api.github.com/repos/grimme-lab/xtb/releases/latest"
        $XTB_VERSION = $XTB_RELEASE.tag_name -replace '^v', ''
    } catch {
        Write-Host "Warning: Failed to get XTB version, skipping XTB installation" -ForegroundColor Yellow
        $XTB_VERSION = ""
    }

    if (![string]::IsNullOrEmpty($XTB_VERSION)) {
        Write-Host "XTB version: $XTB_VERSION"
        
        # Construct XTB download URL for Windows
        $XTB_ARCHIVE = "xtb-${XTB_VERSION}-windows-x86_64.zip"
        $XTB_URL = "https://github.com/grimme-lab/xtb/releases/download/v${XTB_VERSION}/${XTB_ARCHIVE}"
        Write-Host "Download URL: $XTB_URL"
        
        # Download and extract XTB
        $XTB_ARCHIVE_PATH = Join-Path $WORKSHOP_DIR $XTB_ARCHIVE
        try {
            Invoke-WebRequest -Uri $XTB_URL -OutFile $XTB_ARCHIVE_PATH
            Write-Host "Extracting XTB..."
            Expand-Archive -Path $XTB_ARCHIVE_PATH -DestinationPath $WORKSHOP_DIR -Force
            
            # Find extracted directory and copy executable
            $XTB_EXTRACTED_DIR = Join-Path $WORKSHOP_DIR "xtb-${XTB_VERSION}"
            if (Test-Path $XTB_EXTRACTED_DIR) {
                $XTB_EXE = Join-Path $XTB_EXTRACTED_DIR "bin\xtb.exe"
                if (Test-Path $XTB_EXE) {
                    Copy-Item $XTB_EXE -Destination $BIN_DIR -Force
                    Write-Host "✓ XTB installation successful!" -ForegroundColor Green
                    
                    # Copy XTB data files if they exist
                    $XTB_SHARE_DIR = Join-Path $XTB_EXTRACTED_DIR "share"
                    if (Test-Path $XTB_SHARE_DIR) {
                        if (!(Test-Path (Join-Path $WORKSHOP_DIR "share"))) {
                            New-Item -ItemType Directory -Path (Join-Path $WORKSHOP_DIR "share") -Force | Out-Null
                        }
                        Copy-Item -Path "$XTB_SHARE_DIR\*" -Destination (Join-Path $WORKSHOP_DIR "share") -Recurse -Force -ErrorAction SilentlyContinue
                    }
                } else {
                    Write-Host "Warning: XTB executable not found in expected location" -ForegroundColor Yellow
                    # Try to find it in different locations
                    $XTB_PATH = Get-ChildItem -Path $XTB_EXTRACTED_DIR -Filter "xtb.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($XTB_PATH) {
                        Copy-Item $XTB_PATH.FullName -Destination $BIN_DIR -Force
                        Write-Host "✓ Found and installed XTB from: $($XTB_PATH.FullName)" -ForegroundColor Green
                    } else {
                        Write-Host "Warning: Could not find XTB executable anywhere in archive" -ForegroundColor Yellow
                    }
                }
                Remove-Item -Path $XTB_EXTRACTED_DIR -Recurse -Force
            } else {
                Write-Host "Warning: XTB extraction failed" -ForegroundColor Yellow
            }
            Remove-Item -Path $XTB_ARCHIVE_PATH -Force
        } catch {
            Write-Host "Warning: Failed to download XTB from $XTB_URL" -ForegroundColor Yellow
        }
    }
}

# Note: setup_env.ps1 already exists as a standalone file in the repository root

# Test installations
Write-Host ""
Write-Host "Testing installations..."
$env:PATH = "$BIN_DIR;$env:PATH"
if (Test-Path "$WORKSHOP_DIR\share\occ") {
    $env:OCC_DATA_PATH = "$WORKSHOP_DIR\share\occ"
}

# Test OCC
$OCC_EXE = Join-Path $BIN_DIR "occ.exe"
try {
    & $OCC_EXE --help 2>&1 | Out-Null
    Write-Host "✓ OCC installation successful!" -ForegroundColor Green
} catch {
    Write-Host "✗ OCC installation failed!" -ForegroundColor Red
    Write-Host "Check that the binary is working:"
    Write-Host "  $OCC_EXE --help"
    exit 1
}

# Test XTB if installed
$XTB_EXE = Join-Path $BIN_DIR "xtb.exe"
if (Test-Path $XTB_EXE) {
    try {
        & $XTB_EXE --help 2>&1 | Out-Null
        Write-Host "✓ XTB installation successful!" -ForegroundColor Green
    } catch {
        Write-Host "⚠ XTB installed but not working properly" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "1. Run: . .\setup_env.ps1"
Write-Host "2. Test: .\scripts\test_installation.ps1"
Write-Host "3. Start workshop: see geometries\ directory"