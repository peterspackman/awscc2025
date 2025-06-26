# Installation Scripts

This directory contains platform-specific installation scripts for the AWSCC 2025 workshop.

## Quick Start

### macOS/Linux
```bash
./setup.sh
source ../setup_env.sh
```

### Windows
```powershell
.\setup.ps1
. ..\setup_env.ps1
```

## What These Scripts Do

1. **Detect your platform** (macOS, Linux, Windows)
2. **Download the latest OCC release** from GitHub
3. **Extract and install** OCC to a local `bin/` directory
4. **Set up data files** and environment variables
5. **Create environment setup script** for easy activation
6. **Test the installation** to ensure everything works

## Platform Support

| Platform | Script | Status |
|----------|--------|--------|
| macOS (Intel) | `setup.sh` | ✅ Supported |
| macOS (Apple Silicon) | `setup.sh` | ✅ Supported |
| Linux (x64) | `setup.sh` | ✅ Supported |
| Windows (x64) | `setup.ps1` | ✅ Supported |

## Installation Details

### Where Files Are Installed

```
awscc_workshop_2025/
├── bin/                     # OCC executable
│   └── occ                  # or occ.exe on Windows
├── data/                    # OCC data files (if included)
│   └── share/
└── setup_env.sh            # Environment setup script
```

### Environment Variables Set

- **PATH**: Adds the local `bin/` directory
- **OCC_DATA_PATH**: Points to the data files (if available)

## Using OCC After Installation

Each time you start a new terminal session, you need to activate the workshop environment:

**macOS/Linux:**
```bash
cd awscc_workshop_2025
source setup_env.sh
occ --help
```

**Windows:**
```powershell
cd awscc_workshop_2025
. .\setup_env.ps1
occ --help
```

## Alternative Installation Methods

### Option 1: UV Python Tool
```bash
uv tool install occpy
# Then use 'occpy' instead of 'occ'
```

### Option 2: Manual Installation
1. Download from: https://github.com/peterspackman/occ/releases
2. Extract to your preferred location
3. Add to PATH manually
4. Set OCC_DATA_PATH if needed

### Option 3: System Package Manager
```bash
# On macOS with Homebrew (if available)
brew install peterspackman/tap/occ

# On conda
conda install -c conda-forge occ
```

## Troubleshooting

### Common Issues

**"occ: command not found"**
- Make sure you've run `source setup_env.sh` (or `. .\setup_env.ps1` on Windows)
- Check that the binary exists in `bin/occ`

**Download fails**
- Check internet connection
- Try running the script again (GitHub API rate limits)
- Download manually from the releases page

**Permission errors on macOS/Linux**
- The setup script should handle permissions automatically
- If needed: `chmod +x bin/occ`

**Windows execution policy**
- You may need to run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Verification Commands

Test your installation:
```bash
# Check OCC is available
occ --help

# Check version info
occ --version

# Test basic functionality
occ scf --help
```

### Platform-Specific Notes

**macOS:**
- On first run, you may see a security warning
- Go to System Preferences → Security & Privacy to allow the app

**Linux:**
- Ensure you have basic build tools if compilation is needed
- Some systems may need additional libraries

**Windows:**
- PowerShell 5.0+ recommended
- Windows Defender may scan the executable on first run

## Support

If you encounter issues:
1. Check this README for common solutions
2. Verify your platform is supported
3. Try the alternative installation methods
4. Create an issue in the workshop repository

---

**Last Updated:** January 2025