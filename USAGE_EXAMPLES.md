# Usage Examples

This document provides practical, copy-paste examples for running the End Reason Tagger pipeline.

## Prerequisites

Before running these examples, ensure you have:
- Nextflow (≥21.04.0) installed: `nextflow -version`
- Docker installed (recommended), or Conda/Mamba
- Your BAM files ready
- (Optional) POD5 files from your Oxford Nanopore sequencing run

## Example 1: Tag a Single BAM File (Quickest Start)

```bash
# Without POD5 data (adds quality and length tags only)
nextflow run main.nf \
  --bam_input /path/to/your/sample.bam \
  --outdir results

# Output: results/tagged/sample.endtag.bam
```

**What this does:**
- Adds `P5=0`, `AQ` (quality), `LE` (length), `ZE=NO_POD5` tags
- Useful for basic QC metrics without POD5 data

## Example 2: Tag with POD5 Data (Full Tagging)

```bash
nextflow run main.nf \
  --bam_input /path/to/your/sample.bam \
  --pod5_dir /path/to/pod5_files/ \
  --outdir results

# Output: results/tagged/sample.endtag.bam with full end_reason tags
```

**What this does:**
- Adds all tags: `ER`, `ZE`, `NS`, `CH`, `SS`, `P5=1`, `AQ`, `LE`
- Matches reads to POD5 metadata by read ID
- Adds end reason information (why sequencing stopped)

## Example 3: Batch Process Multiple BAM Files

```bash
# Process all BAM files in a directory
nextflow run main.nf \
  --bam_input /path/to/bam_directory/ \
  --pod5_dir /path/to/pod5_files/ \
  --outdir results

# Output: results/tagged/ with one .endtag.bam per input BAM
```

## Example 4: Speed Up with POD5 JSON Caching

```bash
# First run: Extract and cache POD5 metadata
nextflow run main.nf \
  --bam_input batch1/*.bam \
  --pod5_dir /large/pod5/directory/ \
  --write_pod5_json pod5_metadata.json \
  --outdir results/batch1

# Subsequent runs: Reuse cached metadata (much faster!)
nextflow run main.nf \
  --bam_input batch2/*.bam \
  --pod5_json pod5_metadata.json \
  --outdir results/batch2
```

**When to use this:**
- Processing multiple batches of BAMs from the same sequencing run
- POD5 extraction is slow (large POD5 files)
- Saves time by reading POD5 files only once

## Example 5: Run on HPC with SLURM

```bash
nextflow run main.nf \
  -profile slurm \
  --bam_input /data/bam_files/ \
  --pod5_dir /data/pod5_files/ \
  --outdir /scratch/results
```

**Note:** Edit `nextflow.config` to set your SLURM account and queue:
```groovy
slurm {
    process.queue = 'your-queue-name'
    process.clusterOptions = '--account=your-account'
}
```

## Example 6: Debug Mode (Verbose Logging)

```bash
nextflow run main.nf \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  --log_level DEBUG \
  --outdir results
```

**Useful for:**
- Troubleshooting issues
- Understanding what the pipeline is doing
- Checking why reads aren't matching POD5 data

## Example 7: Low-Memory Testing

```bash
nextflow run main.nf \
  -profile test \
  --bam_input small_sample.bam \
  --pod5_dir pod5_files/ \
  --outdir test_results
```

**What the test profile does:**
- Uses minimal resources (1 CPU, 2 GB RAM)
- Good for testing on laptops or limited systems

## Verifying Results

After running the pipeline, verify your results:

```bash
# Check output files exist
ls -lh results/tagged/

# Verify BAM integrity
samtools quickcheck results/tagged/*.bam && echo "✓ All BAMs are valid"

# View tags on first read
samtools view results/tagged/*.endtag.bam | head -1

# Extract specific tags
samtools view results/tagged/*.endtag.bam | \
  awk '{for(i=12;i<=NF;i++){if($i~/^(ER|P5|AQ|LE):/)print $i}}' | \
  head -10

# Check end_reason distribution
samtools view results/tagged/*.endtag.bam | \
  grep -o 'ER:Z:[^[:space:]]*' | \
  sort | uniq -c | sort -rn
```

## Understanding the Output

### Output Directory Structure

```
results/
├── tagged/
│   ├── sample1.endtag.bam       # Tagged BAM file
│   ├── sample1.endtag.bam.bai   # BAM index
│   └── sample1.endtag.summary.tsv  # Summary statistics
└── reports/
    ├── execution_report.html     # Pipeline performance report
    ├── timeline.html             # Timeline visualization
    ├── trace.txt                 # Detailed execution trace
    └── dag.html                  # Workflow diagram
```

### Tags in Output BAM

Each read in the output BAM will have these additional tags:

| Tag | Example Value | Meaning |
|-----|---------------|---------|
| `ER:Z:SIGNAL_POSITIVE` | String | End reason from POD5 |
| `ZE:Z:SIGNAL_POSITIVE` | String | End reason (explicit string type) |
| `P5:i:1` | Integer | POD5 data present (1=yes, 0=no) |
| `AQ:f:12.34` | Float | Average quality score (Phred) |
| `LE:i:1523` | Integer | Read length in bases |
| `NS:i:12345` | Integer | Number of samples (POD5) |
| `CH:i:42` | Integer | Channel number (POD5) |
| `SS:i:100000` | Integer | Start sample (POD5) |

**Without POD5 data**, you'll see:
- `P5:i:0`
- `ZE:Z:NO_POD5`
- `AQ` and `LE` still calculated from BAM

## Common Use Cases

### 1. Quality Control Pipeline

```bash
# Tag BAMs for QC analysis
nextflow run main.nf \
  --bam_input sequencing_run/*.bam \
  --pod5_dir pod5_files/ \
  --outdir qc_tagged/

# Then analyze with your QC tools
# Tags provide additional metrics for filtering and QC
```

### 2. Filter by End Reason

```bash
# Tag all reads
nextflow run main.nf \
  --bam_input all_reads.bam \
  --pod5_dir pod5_files/ \
  --outdir tagged/

# Extract only SIGNAL_POSITIVE reads
samtools view -h tagged/tagged/all_reads.endtag.bam | \
  awk '/^@/ || /ER:Z:SIGNAL_POSITIVE/' | \
  samtools view -b -o signal_positive_only.bam
```

### 3. Integration with Downstream Analysis

```bash
# Step 1: Tag with this pipeline
nextflow run main.nf \
  --bam_input input_bams/ \
  --pod5_dir pod5_files/ \
  --outdir tagged_output/

# Step 2: Use tagged BAMs in your analysis pipeline
your_analysis_tool --input tagged_output/tagged/*.endtag.bam
```

## Troubleshooting

### Pipeline doesn't start

```bash
# Check Nextflow installation
nextflow -version

# Run with help to verify pipeline loads
nextflow run main.nf --help
```

### "No POD5 data" warning

This is normal if you didn't provide `--pod5_dir` or `--pod5_json`. The pipeline will still add `AQ` and `LE` tags.

### Memory errors

```bash
# Use test profile with lower memory
nextflow run main.nf -profile test --bam_input sample.bam --outdir results

# Or increase memory in nextflow.config
```

### Check execution logs

```bash
# Main Nextflow log
cat .nextflow.log

# Process-specific logs
ls -lh work/

# View a specific process log (replace XX with actual hash)
cat work/XX/XXXXXXXX/.command.log
```

## Getting Help

- **Show help message:** `nextflow run main.nf --help`
- **Quick start guide:** [QUICK_START.md](QUICK_START.md)
- **Installation help:** [INSTALLATION.md](INSTALLATION.md)
- **Full documentation:** [README.md](README.md)
- **Test data examples:** [test_data/README.md](test_data/README.md)

## Performance Tips

1. **Use POD5 JSON caching** when processing multiple batches from the same run
2. **Process BAMs in parallel** by providing a directory instead of individual files
3. **Use SLURM profile on HPC** for better resource management
4. **Monitor resources** via the execution reports in `results/reports/`
5. **Resume failed runs** with `-resume` flag: `nextflow run main.nf -resume ...`
