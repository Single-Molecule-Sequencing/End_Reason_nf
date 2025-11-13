# EPI2ME Desktop Integration

## Overview

This pipeline can be installed and run through the **EPI2ME Desktop** application, Oxford Nanopore's graphical interface for Nextflow workflows.

## Installation in EPI2ME Desktop

### Method 1: Direct Installation from GitHub

1. **Open EPI2ME Desktop**
   - Launch the EPI2ME Desktop application

2. **Add Workflow**
   - Click "Add Workflow" or "Import Workflow"
   - Select "From GitHub Repository"

3. **Enter Repository URL**
   ```
   https://github.com/Single-Molecule-Sequencing/End_Reason_nf.git
   ```

4. **Configure Installation**
   - The application will detect the `manifest.2me` file
   - Review the workflow details
   - Click "Install"

5. **Wait for Setup**
   - EPI2ME will download the workflow
   - Conda environment will be created automatically
   - Dependencies will be installed

### Method 2: Manual Installation

1. **Clone Repository**
   ```bash
   git clone https://github.com/Single-Molecule-Sequencing/End_Reason_nf.git
   ```

2. **Import to EPI2ME**
   - Open EPI2ME Desktop
   - Click "Add Workflow" → "From Local Directory"
   - Select the `End_Reason_nf` directory
   - EPI2ME will read the `manifest.2me` file

## Using the Workflow in EPI2ME

### Input Configuration

The EPI2ME interface will present these input fields:

#### Required Inputs

1. **BAM Input**
   - Click "Browse" to select your BAM file or directory
   - Accepts: Single `.bam` file or directory containing multiple BAM files
   - Example: `/path/to/sequencing_run/bam_pass/`

2. **Output Directory**
   - Choose where results will be saved
   - Default: `./results`
   - Example: `/path/to/my_analysis/`

#### Optional Inputs

3. **POD5 Directory** (Recommended)
   - Select directory containing POD5 files
   - Without this, only basic tags (AQ, LE) will be added
   - Example: `/path/to/sequencing_run/pod5_pass/`

4. **POD5 Metadata JSON** (Advanced)
   - Pre-extracted POD5 metadata for faster processing
   - Skip this on first run
   - Use cached file from previous run for speedup

#### Advanced Parameters

5. **Cache POD5 Metadata to JSON**
   - Optional: Save POD5 metadata for reuse
   - Recommended for large datasets
   - Example: `/path/to/pod5_metadata.json`

6. **Logging Level**
   - Choose verbosity: DEBUG, INFO, WARNING, ERROR, CRITICAL
   - Default: INFO
   - Use DEBUG for troubleshooting

### Running the Workflow

1. **Configure Inputs**
   - Fill in all required fields
   - Optionally configure advanced parameters

2. **Review Settings**
   - Check the configuration summary
   - Verify input paths are correct

3. **Click "Run"**
   - Workflow will start executing
   - Progress will be shown in real-time

4. **Monitor Progress**
   - View live log output
   - Check resource usage
   - See estimated completion time

5. **Results**
   - Output files will be in your specified output directory
   - Tagged BAM files in `output_dir/tagged/`
   - Reports in `output_dir/reports/`

## Output Files

After successful completion, you'll find:

### Tagged BAM Files
```
results/
└── tagged/
    ├── sample1.endtag.bam        # Tagged BAM
    ├── sample1.endtag.bam.bai    # BAM index
    ├── sample1.endtag.summary.tsv # Summary stats
    └── ...
```

### Reports
```
results/
└── reports/
    ├── execution_report.html   # Detailed execution report
    ├── timeline.html          # Timeline visualization
    ├── trace.txt              # Resource usage trace
    └── dag.html               # Workflow diagram
```

## Understanding the Output

### Tagged BAM Files

Each read in the output BAM has these new tags:

| Tag | Example | Meaning |
|-----|---------|---------|
| `ER:Z:SIGNAL_POSITIVE` | String | End reason from POD5 |
| `ZE:Z:SIGNAL_POSITIVE` | String | End reason (explicit string) |
| `P5:i:1` | Integer | POD5 data found (1=yes, 0=no) |
| `AQ:f:12.34` | Float | Average quality score |
| `LE:i:1523` | Integer | Read length |
| `NS:i:12345` | Integer | Number of samples (POD5) |
| `CH:i:42` | Integer | Channel number (POD5) |
| `SS:i:100000` | Integer | Start sample (POD5) |

### Viewing Tags

You can view tags using `samtools`:

```bash
# View first few reads with tags
samtools view results/tagged/sample.endtag.bam | head -3

# Extract end_reason distribution
samtools view results/tagged/sample.endtag.bam | \
  grep -o 'ER:Z:[^[:space:]]*' | \
  sort | uniq -c | sort -rn
```

## Workflow Behavior

### With POD5 Files

When POD5 directory is provided:
- ✅ All 8 tags added (ER, ZE, P5, AQ, LE, NS, CH, SS)
- ✅ End reasons extracted and normalized
- ✅ Full metadata available
- ⏱️ First run: ~5-10 minutes per GB
- ⏱️ With cached JSON: ~1-2 minutes per GB

### Without POD5 Files

When no POD5 directory is provided:
- ✅ Basic tags added (AQ, LE, P5=0, ZE="NO_POD5")
- ⚠️ No end_reason information
- ⚠️ No POD5 metadata (NS, CH, SS)
- ⏱️ Faster: ~2-3 minutes per GB

## Performance Tips

### 1. Use POD5 JSON Caching

For multiple BAM files from the same sequencing run:

**First run:**
```
1. Set "Cache POD5 Metadata to JSON" to: pod5_metadata.json
2. Run the workflow
```

**Subsequent runs:**
```
1. Leave "POD5 Directory" empty
2. Set "POD5 Metadata JSON" to: pod5_metadata.json
3. Run the workflow (10x faster!)
```

### 2. Process Multiple BAMs Efficiently

Instead of running once per BAM file:
- Select the entire BAM directory as input
- Pipeline will process all BAMs in parallel
- Much faster than individual runs

### 3. Resource Allocation

If experiencing slowness:
- Check system resources in EPI2ME
- Consider reducing concurrent jobs
- Ensure sufficient disk space

## Troubleshooting

### Common Issues

#### "No POD5 files found"

**Problem**: POD5 directory is empty or contains no `.pod5` files

**Solution**:
- Check the directory path is correct
- Ensure POD5 files have `.pod5` or `.pod5.gz` extension
- Or proceed without POD5 (basic tagging only)

#### "BAM file not found"

**Problem**: Invalid BAM path or file doesn't exist

**Solution**:
- Verify the BAM file path
- Ensure file has `.bam` extension
- Check file permissions

#### "Out of memory"

**Problem**: Insufficient memory for large datasets

**Solution**:
- Close other applications
- Process BAM files one at a time
- Use POD5 JSON caching

#### "Conda environment creation failed"

**Problem**: Network issues or conda timeout

**Solution**:
- Check internet connection
- Retry the installation
- Manually create environment (see INSTALLATION.md)

### Getting Help

1. **Check Logs**
   - EPI2ME shows live logs in the interface
   - Look for error messages
   - Check the work directory for detailed logs

2. **Consult Documentation**
   - README: [Link](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/blob/main/README.md)
   - INSTALLATION: [Link](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/blob/main/INSTALLATION.md)
   - QUICK_START: [Link](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/blob/main/QUICK_START.md)

3. **Report Issues**
   - GitHub Issues: [Link](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/issues)
   - Include:
     - EPI2ME version
     - Error messages
     - Input file details
     - System information

## Advanced Configuration

### Custom Nextflow Profiles

EPI2ME uses the `standard` profile by default. To use other profiles:

1. **Edit Configuration**
   - In EPI2ME, go to workflow settings
   - Add custom Nextflow options:
     ```
     -profile slurm
     ```

2. **Available Profiles**
   - `standard` - Default, local execution
   - `local` - Explicit local execution
   - `slurm` - HPC SLURM execution
   - `test` - Minimal resources for testing

### Resource Limits

To customize resources in EPI2ME:

```
-process.cpus 8
-process.memory '16 GB'
```

## Example Workflows

### Example 1: First Time User

1. Install workflow in EPI2ME Desktop
2. Select BAM file: `/data/run1/bam_pass/sample1.bam`
3. Select POD5 directory: `/data/run1/pod5_pass/`
4. Set output: `/data/analysis/run1_tagged/`
5. Click "Run"
6. Wait 5-10 minutes
7. Check results in `/data/analysis/run1_tagged/tagged/`

### Example 2: Batch Processing with Caching

**First BAM:**
1. BAM input: `/data/run1/bam_pass/sample1.bam`
2. POD5 directory: `/data/run1/pod5_pass/`
3. Cache to: `/data/run1_pod5_cache.json`
4. Output: `/data/analysis/sample1/`
5. Run

**Subsequent BAMs:**
1. BAM input: `/data/run1/bam_pass/sample2.bam`
2. POD5 JSON: `/data/run1_pod5_cache.json` (from previous run)
3. Output: `/data/analysis/sample2/`
4. Run (much faster!)

### Example 3: QC Analysis

After tagging, use the tagged BAMs for QC:

1. Run this workflow to tag BAMs
2. Open tagged BAMs in other EPI2ME workflows
3. Use end_reason tags for filtering/analysis
4. Generate QC reports based on end_reasons

## Integration with Other Workflows

The tagged BAM files can be used in:

- **Alignment workflows**: Already aligned, just tagged
- **Variant calling**: Use tags for filtering
- **QC pipelines**: Analyze by end_reason
- **Assembly workflows**: Filter by end_reason first
- **Downstream analysis**: Any workflow accepting BAM input

## Version Information

- **Workflow Version**: 1.0.0
- **Manifest Version**: 1.0
- **EPI2ME Compatibility**: >= 4.0.0
- **Nextflow Required**: >= 21.04.0

## Updates

To update the workflow in EPI2ME:

1. Open EPI2ME Desktop
2. Go to installed workflows
3. Find "End Reason Tagger"
4. Click "Update"
5. EPI2ME will fetch latest version from GitHub

## Support

For support:
- **Documentation**: GitHub repository
- **Issues**: GitHub Issues tracker
- **Community**: EPI2ME Community forums
- **Email**: Through GitHub Issues

---

## Quick Reference Card

### Minimum Requirements
- EPI2ME Desktop >= 4.0.0
- 4 GB RAM
- 2 CPU cores
- 10 GB free disk space

### Typical Runtime
- 5-10 minutes per GB BAM (with POD5)
- 2-3 minutes per GB BAM (without POD5)
- 1-2 minutes per GB (with cached POD5 JSON)

### Input Files
- **Required**: BAM file(s)
- **Optional**: POD5 directory
- **Optional**: POD5 JSON cache

### Output Files
- Tagged BAM files (*.endtag.bam)
- BAM indexes (*.endtag.bam.bai)
- Summary statistics (*.summary.tsv)
- Execution reports (HTML)

### Tags Added
- ER - End reason
- ZE - End reason (string)
- P5 - POD5 present flag
- AQ - Average quality
- LE - Read length
- NS, CH, SS - POD5 metadata

---

**Ready to use!** Install in EPI2ME Desktop and start tagging your BAM files.
