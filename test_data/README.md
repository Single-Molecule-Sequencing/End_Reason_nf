# Test Data for End Reason Tagger Pipeline

## Overview

This directory contains test data and scripts for validating the Nextflow End Reason Tagger pipeline.

## Test Data Locations

The pipeline can be tested using data from the parent repository:

### Option 1: Use end_reason_ont test data

```bash
# Location of test data in parent repository
TEST_DATA_DIR="../end_reason_ont/tests/data/example_run/example_data_folder"

# BAM files
BAM_DIR="$TEST_DATA_DIR/bam_pass"

# Sequencing summary (can be used to create POD5 metadata)
SUMMARY_FILE="$TEST_DATA_DIR/sequencing_summary_AWG074_6e9943cf_9a0ad63c.txt"
```

### Option 2: Use production data

If you have access to production nanopore data:

```bash
# POD5 files location
POD5_DIR="/path/to/your/pod5_files"

# BAM files location
BAM_DIR="/path/to/your/bam_files"
```

## Running Tests

### Quick Test (Local)

```bash
# From the Nextflow_End_Reason directory
cd ../ && cd Nextflow_End_Reason

# Test with minimal data
nextflow run main.nf \
  --bam_input ../end_reason_ont/signal_positive.bam \
  --pod5_dir /path/to/pod5/files \
  --outdir ./test_results \
  -profile test
```

### Full Test Suite

```bash
# Test 1: Single BAM file
nextflow run main.nf \
  --bam_input test_data/sample.bam \
  --pod5_dir test_data/pod5_files \
  --outdir test_results/test1

# Test 2: Directory of BAM files
nextflow run main.nf \
  --bam_input test_data/bam_files \
  --pod5_dir test_data/pod5_files \
  --outdir test_results/test2

# Test 3: With POD5 JSON caching
nextflow run main.nf \
  --bam_input test_data/sample.bam \
  --pod5_dir test_data/pod5_files \
  --write_pod5_json test_results/pod5_metadata.json \
  --outdir test_results/test3

# Test 4: Reuse POD5 JSON (faster)
nextflow run main.nf \
  --bam_input test_data/sample.bam \
  --pod5_json test_results/pod5_metadata.json \
  --outdir test_results/test4

# Test 5: No POD5 data (should still tag with P5=0)
nextflow run main.nf \
  --bam_input test_data/sample.bam \
  --outdir test_results/test5
```

## Validating Results

After running the pipeline, validate the outputs:

```bash
# Check that tagged BAM files exist
ls -lh test_results/tagged/*.bam

# Verify BAM file integrity
samtools quickcheck test_results/tagged/*.bam

# View tags on a few reads
samtools view test_results/tagged/sample.endtag.bam | head -3

# Extract and view specific tags
samtools view test_results/tagged/sample.endtag.bam | \
  awk '{for(i=12;i<=NF;i++){if($i~/^ER:Z:|^P5:i:|^AQ:f:/){print $i}}}' | \
  head -10

# Check end_reason distribution
samtools view test_results/tagged/sample.endtag.bam | \
  grep -o 'ER:Z:[^[:space:]]*' | \
  sort | uniq -c | sort -rn

# Verify all reads have P5 tag
samtools view test_results/tagged/sample.endtag.bam | \
  grep -c 'P5:i:' || echo "Missing P5 tags!"

# Check summary statistics
cat test_results/tagged/*.summary.tsv
```

## Expected Output

### Tagged BAM File Structure

Each tagged read should have:
- Original alignment information (unchanged)
- New tags: ER, ZE, NS, CH, SS, P5, AQ, LE
- Same number of reads as input BAM

### Tag Examples

```
ER:Z:SIGNAL_POSITIVE       # End reason
ZE:Z:SIGNAL_POSITIVE       # End reason (string type)
NS:i:12345                 # Number of samples
CH:i:42                    # Channel number
SS:i:100000                # Start sample
P5:i:1                     # POD5 data present (1=yes, 0=no)
AQ:f:12.34                 # Average quality score
LE:i:1523                  # Read length
```

### Reports

Check the generated reports:
```bash
# Open execution report
firefox test_results/reports/execution_report.html

# View timeline
firefox test_results/reports/timeline.html

# Check trace file
cat test_results/reports/trace.txt
```

## Troubleshooting Test Failures

### No POD5 files available

If you don't have POD5 files:
- The pipeline will still run and tag reads with `P5=0`
- Other computed tags (AQ, LE) will still be added
- This is useful for testing the BAM processing logic

### Conda environment issues

```bash
# Clear conda cache
conda clean --all

# Manually create environment
conda env create -f envs/tagger.yaml
conda activate tagger

# Test the script directly
./bin/tag_end_reason.py --help
```

### Memory errors during testing

Use the test profile which has lower resource requirements:
```bash
nextflow run main.nf -profile test --bam_input ... --outdir ...
```

## Performance Benchmarking

To benchmark performance:

```bash
# Time the execution
time nextflow run main.nf \
  --bam_input large_dataset/*.bam \
  --pod5_dir pod5_files \
  --outdir benchmark_results

# Check resource usage in trace file
cat benchmark_results/reports/trace.txt
```

## Integration Testing

Test integration with the nanopore_analyzer package:

```bash
# 1. Tag BAMs with Nextflow
nextflow run main.nf \
  --bam_input input_bams \
  --pod5_dir pod5_files \
  --outdir tagged_output

# 2. Analyze with nanopore_analyzer (reads ER tags from BAM)
cd ../end_reason_ont
nanopore_analyzer \
  --bam_input ../Nextflow_End_Reason/tagged_output/tagged/*.bam \
  --outdir analysis_results
```

## Creating Test Data

To create minimal test data:

```bash
# Extract a subset of reads from a large BAM
samtools view -s 0.001 large_file.bam -o test_data/sample.bam

# Create corresponding POD5 subset (requires pod5 tools)
# This is more complex and requires matching read IDs
```
