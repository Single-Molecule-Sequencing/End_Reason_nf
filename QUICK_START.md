# Quick Start Guide

## TL;DR

```bash
# 1. Navigate to pipeline directory
cd Nextflow_End_Reason

# 2. Run the pipeline
nextflow run main.nf \
  --pod5_dir /path/to/pod5_files \
  --bam_input /path/to/bam_files \
  --outdir results

# 3. Check outputs
ls -lh results/tagged/
samtools view results/tagged/*.endtag.bam | head
```

## Prerequisites Checklist

- [ ] Nextflow >= 21.04.0 installed
- [ ] Conda or Mamba installed
- [ ] Samtools available
- [ ] POD5 files (or can run without for basic tagging)
- [ ] BAM files to tag

## Common Commands

### Display Help
```bash
nextflow run main.nf --help
```

### Tag Single BAM File
```bash
nextflow run main.nf \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  --outdir output/
```

### Tag Multiple BAM Files
```bash
nextflow run main.nf \
  --bam_input bam_directory/ \
  --pod5_dir pod5_files/ \
  --outdir output/
```

### Without POD5 Data
```bash
# Still adds AQ, LE tags and marks P5=0
nextflow run main.nf \
  --bam_input sample.bam \
  --outdir output/
```

### With POD5 JSON Caching
```bash
# First run: extract and save POD5 metadata
nextflow run main.nf \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  --write_pod5_json pod5_metadata.json \
  --outdir output/

# Subsequent runs: use cached metadata (much faster)
nextflow run main.nf \
  --bam_input other_sample.bam \
  --pod5_json pod5_metadata.json \
  --outdir output2/
```

### On SLURM/HPC
```bash
nextflow run main.nf \
  -profile slurm \
  --bam_input bam_files/ \
  --pod5_dir pod5_files/ \
  --outdir output/
```

### With Debug Logging
```bash
nextflow run main.nf \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  --log_level DEBUG \
  --outdir output/
```

## Understanding Output

### Output Directory Structure
```
results/
├── tagged/
│   ├── sample1.endtag.bam       # Tagged BAM file
│   ├── sample1.endtag.bam.bai   # BAM index
│   ├── sample1.endtag.summary.tsv
│   └── ...
└── reports/
    ├── execution_report.html     # Pipeline execution summary
    ├── timeline.html             # Timeline visualization
    ├── trace.txt                 # Resource usage details
    └── dag.html                  # Workflow DAG
```

### Tags Added to Each Read

| Tag | Example | Meaning |
|-----|---------|---------|
| `ER:Z:SIGNAL_POSITIVE` | String | End reason from POD5 |
| `ZE:Z:SIGNAL_POSITIVE` | String | End reason (explicit string type) |
| `P5:i:1` | Integer | POD5 data present (1=yes, 0=no) |
| `AQ:f:12.34` | Float | Average quality score |
| `LE:i:1523` | Integer | Read length |
| `NS:i:12345` | Integer | Number of samples (POD5) |
| `CH:i:42` | Integer | Channel number (POD5) |
| `SS:i:100000` | Integer | Start sample (POD5) |

## Quick Validation

```bash
# Check BAM file integrity
samtools quickcheck results/tagged/*.bam && echo "OK"

# View tags on first read
samtools view results/tagged/*.endtag.bam | head -1

# Check end_reason distribution
samtools view results/tagged/*.endtag.bam | \
  grep -o 'ER:Z:[^[:space:]]*' | sort | uniq -c

# Verify all reads have P5 tag
samtools view results/tagged/*.endtag.bam | grep -c 'P5:i:'
```

## Troubleshooting

### "nextflow: command not found"
```bash
# Use full path or add to PATH
export PATH="/path/to/nextflow:$PATH"
```

### "No module named 'pod5'"
```bash
# Conda will handle this automatically
# Or manually create environment:
conda env create -f envs/tagger.yaml
```

### Pipeline fails with memory error
```bash
# Use test profile with lower resources
nextflow run main.nf -profile test ...
```

### Check execution logs
```bash
# Main log
cat .nextflow.log

# Process logs (replace with actual work hash)
cat work/xx/xxxxxxxxx/.command.log
```

## Parameters Reference

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--bam_input` | Yes | - | BAM file or directory |
| `--pod5_dir` | No | null | POD5 file or directory |
| `--pod5_json` | No | null | Pre-extracted POD5 JSON |
| `--outdir` | No | ./results | Output directory |
| `--write_pod5_json` | No | null | Save POD5 metadata path |
| `--log_level` | No | INFO | DEBUG/INFO/WARNING/ERROR |

## Performance Tips

1. **Use POD5 JSON caching** for multiple runs with same POD5 data
2. **Process in batches** if you have many BAM files
3. **Use SLURM profile** on HPC for better resource management
4. **Monitor resources** via timeline.html report

## Getting More Help

- Full documentation: [README.md](README.md)
- Installation guide: [INSTALLATION.md](INSTALLATION.md)
- Testing guide: [test_data/README.md](test_data/README.md)
- Import details: [IMPORT_SUMMARY.md](IMPORT_SUMMARY.md)

## Example Workflow

```bash
# 1. Check prerequisites
nextflow -version
conda --version
samtools --version

# 2. Review help
nextflow run main.nf --help

# 3. Test with small dataset
nextflow run main.nf \
  --bam_input test.bam \
  --pod5_dir pod5/ \
  --outdir test_run/ \
  -profile test

# 4. Validate output
samtools quickcheck test_run/tagged/*.bam
samtools view test_run/tagged/*.bam | head

# 5. Process full dataset
nextflow run main.nf \
  --bam_input all_bams/ \
  --pod5_dir pod5/ \
  --write_pod5_json pod5_cache.json \
  --outdir production_run/

# 6. Review execution report
firefox production_run/reports/execution_report.html
```

## Integration Example

Combine with `nanopore_analyzer` for complete analysis:

```bash
# 1. Tag BAMs with Nextflow
nextflow run main.nf \
  --bam_input input_bams/ \
  --pod5_dir pod5_files/ \
  --outdir tagged_output/

# 2. Analyze with nanopore_analyzer
cd ../end_reason_ont
nanopore_analyzer \
  --bam_input ../Nextflow_End_Reason/tagged_output/tagged/*.bam \
  --outdir analysis_results/ \
  --interactive

# 3. View results
firefox analysis_results/reports/*.html
```

---

**Ready to start?** Run `nextflow run main.nf --help`
