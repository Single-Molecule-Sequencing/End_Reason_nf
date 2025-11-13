# Installation Guide

## Prerequisites

### 1. Nextflow

The pipeline requires Nextflow (version >= 21.04.0).

**Check if Nextflow is installed:**
```bash
nextflow -version
```

**If not in PATH, use the copy in parent directory:**
```bash
# From the end_reason directory
../nextflow -version

# Or add to your session PATH
export PATH="$(cd .. && pwd):$PATH"
nextflow -version
```

**To install Nextflow (if needed):**
```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
# Move to a directory in your PATH or use full path
```

### 2. Conda/Mamba

The pipeline uses Conda to manage Python dependencies automatically.

**Check if Conda is installed:**
```bash
conda --version
```

**If not installed, install Miniconda:**
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

### 3. Samtools

Samtools is required for BAM file validation and indexing.

**Check if samtools is installed:**
```bash
samtools --version
```

**Install via conda (recommended):**
```bash
conda install -c bioconda samtools=1.20
```

## Setting Up the Environment

### Option 1: Let Nextflow Handle It (Recommended)

Nextflow will automatically create the conda environment when you run the pipeline for the first time:

```bash
nextflow run main.nf --help
```

The first run will take longer as it creates the conda environment. Subsequent runs will be faster.

### Option 2: Pre-create the Conda Environment

```bash
# Create the environment
conda env create -f envs/tagger.yaml

# Activate it
conda activate tagger

# Verify installation
python3 -c "import pod5, pysam; print('Dependencies OK')"

# Test the script
./bin/tag_end_reason.py --help
```

## Verifying Installation

### Quick Verification

```bash
# 1. Check Nextflow
nextflow -version
# Should show: nextflow version 21.04.0 or higher

# 2. Check Conda
conda --version
# Should show: conda 4.x.x or higher

# 3. Test the pipeline help
nextflow run main.nf --help
# Should display the help message

# 4. Check environment creation
# Look for: .nextflow/conda/ directory after first run
```

### Full Verification

Run the test script:
```bash
./test_pipeline.sh
```

This will:
- Test the help message
- Process a test BAM file without POD5 data
- Validate output BAM files
- Check for required tags

## Troubleshooting

### "nextflow: command not found"

**Solution 1**: Use full path to nextflow
```bash
# From end_reason/Nextflow_End_Reason
../../nextflow run main.nf --help
```

**Solution 2**: Add nextflow to PATH
```bash
export PATH="/path/to/nextflow/directory:$PATH"
```

**Solution 3**: Create symlink
```bash
sudo ln -s /path/to/nextflow /usr/local/bin/nextflow
```

### "ModuleNotFoundError: No module named 'pod5'"

This means the conda environment hasn't been created yet. Solutions:

**Let Nextflow handle it** (recommended):
```bash
nextflow run main.nf --help
```

**Or manually create the environment**:
```bash
conda env create -f envs/tagger.yaml
conda activate tagger
```

### Conda environment creation timeout

If conda is taking too long to create the environment:

```bash
# Install mamba (faster conda replacement)
conda install -c conda-forge mamba

# Edit nextflow.config to use mamba
# Change: conda.useMamba = false
# To:     conda.useMamba = true
```

### Permission denied when running scripts

```bash
chmod +x bin/tag_end_reason.py
chmod +x test_pipeline.sh
```

### Samtools not found during pipeline execution

The conda environment should include samtools. If not:

```bash
# Add samtools to the environment
conda activate tagger
conda install -c bioconda samtools=1.20
```

## Using on HPC Systems

### SLURM Clusters

The pipeline includes a SLURM profile. Configure it for your system:

1. Edit `nextflow.config`
2. Update the SLURM parameters:
   ```groovy
   slurm {
       process.executor = 'slurm'
       process.queue = 'your-queue-name'
       process.clusterOptions = '--account=your-account'
   }
   ```

3. Run with SLURM profile:
   ```bash
   nextflow run main.nf -profile slurm \
     --bam_input ... \
     --pod5_dir ... \
     --outdir ...
   ```

### Module Systems

If your HPC uses environment modules:

```bash
# Load required modules
module load nextflow
module load conda
module load samtools

# Then run the pipeline
nextflow run main.nf --help
```

## System Requirements

### Minimum Requirements
- CPU: 2 cores
- RAM: 4 GB
- Disk: 10 GB free space (for conda environment and temporary files)
- OS: Linux (recommended), macOS, Windows WSL2

### Recommended for Production
- CPU: 4-8 cores (for parallel processing)
- RAM: 8-16 GB
- Disk: 50+ GB (depends on dataset size)
- OS: Linux

## Next Steps

After installation:

1. Read the main [README.md](README.md) for usage instructions
2. Review test data options in [test_data/README.md](test_data/README.md)
3. Run the test script: `./test_pipeline.sh`
4. Process your data!

## Getting Help

- Check the [README.md](README.md) for usage examples
- Review [test_data/README.md](test_data/README.md) for validation
- Check Nextflow logs in `.nextflow.log`
- Review process logs in `work/` directory
- Check execution reports in `results/reports/`
