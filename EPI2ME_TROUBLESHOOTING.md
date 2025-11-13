# EPI2ME Desktop Integration - Troubleshooting Guide

## Issue: Workflow Installation Failed

If you encountered errors when trying to install this workflow in EPI2ME Desktop, this was due to an incorrect manifest format in earlier versions.

## ✅ Fixed in Latest Version (Commit f2268cb)

### What Was Wrong

The initial implementation used a `manifest.2me` file, which is **not** the correct format for importing workflows from GitHub. The `.2me` format is a proprietary packaging format created by Oxford Nanopore's CDN for bundled workflows, not something manually created for GitHub imports.

### What Was Fixed

1. **Removed**: Incorrect `manifest.2me` file
2. **Added**: Proper `nextflow_schema.json` file following EPI2ME workflow standards
3. **Updated**: EPI2ME_INTEGRATION.md with correct installation instructions
4. **Fixed**: .gitignore to preserve essential JSON configuration files

### The Correct Format

EPI2ME Desktop workflows imported from GitHub require a **`nextflow_schema.json`** file that:
- Follows JSON Schema Draft-07 specification
- Defines input parameters with proper types and validation
- Includes output specifications
- Provides help text and descriptions
- Follows the format used by official epi2me-labs workflows

## How to Install (Correct Method)

### Prerequisites

- **EPI2ME Desktop Version**: 5.0.0 or later (with Nextflow schema support)
- **Internet Connection**: For downloading from GitHub
- **Conda**: Automatically handled by EPI2ME Desktop

### Installation Steps

1. **Open EPI2ME Desktop**
   - Launch the application

2. **Import Workflow**
   - Click "Import Workflow" or the "+" button
   - Select "From GitHub Repository"

3. **Enter Repository URL**
   ```
   https://github.com/Single-Molecule-Sequencing/End_Reason_nf
   ```

4. **Complete Import**
   - EPI2ME will read the `nextflow_schema.json` file
   - The workflow parameters will be automatically detected
   - Click "Add" to complete the installation

5. **Ready to Use**
   - The workflow will appear in your workflow list
   - First run may take longer while conda environment is created

## Verification

After installation, you should see:
- **Workflow Name**: "End Reason Tagger"
- **Parameters**: Automatically populated from schema
  - BAM Input (required)
  - POD5 Directory (optional)
  - POD5 Metadata JSON (optional)
  - Output Directory
  - Logging Level (advanced)

## Still Having Issues?

### GitHub URL Not Found

**Problem**: "Repository not found" or "Link not found" error

**Solutions**:
1. Verify the repository is public and accessible
2. Try the full git URL: `https://github.com/Single-Molecule-Sequencing/End_Reason_nf.git`
3. Ensure you're using the latest version of EPI2ME Desktop
4. Check your internet connection

### Schema Not Detected

**Problem**: EPI2ME doesn't recognize the workflow parameters

**Solutions**:
1. Ensure you're using EPI2ME Desktop 5.0.0 or later
2. Update EPI2ME Desktop to the latest version
3. Try re-importing after updating
4. Check that `nextflow_schema.json` exists in the repository (it should after commit f2268cb)

### Local Directory Import Fails

**Problem**: Importing from local clone doesn't work

**Solutions**:
1. Ensure you've cloned the latest version: `git pull origin main`
2. Verify `nextflow_schema.json` exists in the directory
3. Make sure the directory contains `main.nf` and `nextflow.config`
4. Check EPI2ME Desktop logs for specific error messages

### Conda Environment Creation Fails

**Problem**: Dependencies fail to install

**Solutions**:
1. Check your internet connection (conda needs to download packages)
2. Ensure sufficient disk space (conda environments can be large)
3. Try clearing conda cache: EPI2ME Desktop → Settings → Clear cache
4. Check the EPI2ME Desktop logs for specific conda errors

## Alternative: Command-Line Installation

If EPI2ME Desktop continues to have issues, you can run the workflow directly with Nextflow:

```bash
# Clone the repository
git clone https://github.com/Single-Molecule-Sequencing/End_Reason_nf.git
cd End_Reason_nf

# Create conda environment
conda env create -f envs/tagger.yaml
conda activate tagger

# Run the workflow
nextflow run main.nf \
  --bam_input your_sample.bam \
  --pod5_dir your_pod5_files/ \
  --outdir results/
```

See [INSTALLATION.md](INSTALLATION.md) and [QUICK_START.md](QUICK_START.md) for detailed command-line usage.

## Reporting Issues

If you continue to experience problems:

1. **Check the logs**:
   - EPI2ME Desktop: Settings → View Logs
   - Look for specific error messages

2. **Gather information**:
   - EPI2ME Desktop version
   - Operating system and version
   - Error messages (screenshots helpful)
   - Steps you followed

3. **Report on GitHub**:
   - Open an issue: https://github.com/Single-Molecule-Sequencing/End_Reason_nf/issues
   - Use the bug report template
   - Include all gathered information

## Related Documentation

- [EPI2ME Integration Guide](EPI2ME_INTEGRATION.md) - Complete usage guide
- [Installation Guide](INSTALLATION.md) - Command-line installation
- [Quick Start](QUICK_START.md) - Quick reference
- [README](README.md) - Main documentation

---

**Last Updated**: 2025-11-12
**Fixed in Commit**: f2268cb
**Status**: ✅ Resolved
