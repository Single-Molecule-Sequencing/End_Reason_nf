#!/bin/bash

#
# Basic Usage Examples for End_Reason_nf Pipeline
#

# ============================================================================
# Example 1: Process a single BAM file with POD5 directory
# ============================================================================
echo "Example 1: Single BAM with POD5"
nextflow run main.nf \
  --bam_input /path/to/sample.bam \
  --pod5_dir /path/to/pod5_files/ \
  --outdir results/example1/

# ============================================================================
# Example 2: Process directory of BAM files
# ============================================================================
echo "Example 2: Multiple BAMs"
nextflow run main.nf \
  --bam_input /path/to/bam_directory/ \
  --pod5_dir /path/to/pod5_files/ \
  --outdir results/example2/

# ============================================================================
# Example 3: Process without POD5 data (quality and length only)
# ============================================================================
echo "Example 3: Without POD5 (basic tagging)"
nextflow run main.nf \
  --bam_input /path/to/sample.bam \
  --outdir results/example3/
# This will add AQ, LE tags and mark P5=0

# ============================================================================
# Example 4: Use POD5 JSON caching for faster processing
# ============================================================================
echo "Example 4: Extract and cache POD5 metadata"
nextflow run main.nf \
  --bam_input /path/to/sample.bam \
  --pod5_dir /path/to/pod5_files/ \
  --write_pod5_json results/pod5_metadata.json \
  --outdir results/example4/

# Subsequent runs can reuse the cached metadata
nextflow run main.nf \
  --bam_input /path/to/another_sample.bam \
  --pod5_json results/pod5_metadata.json \
  --outdir results/example4_reuse/

# ============================================================================
# Example 5: Run on SLURM cluster
# ============================================================================
echo "Example 5: SLURM execution"
nextflow run main.nf \
  -profile slurm \
  --bam_input /path/to/bam_files/ \
  --pod5_dir /path/to/pod5_files/ \
  --outdir results/example5/

# ============================================================================
# Example 6: Test mode with minimal resources
# ============================================================================
echo "Example 6: Test mode"
nextflow run main.nf \
  -profile test \
  --bam_input test_data/sample.bam \
  --pod5_dir test_data/pod5_files/ \
  --outdir test_results/

# ============================================================================
# Example 7: With debug logging
# ============================================================================
echo "Example 7: Debug logging"
nextflow run main.nf \
  --bam_input /path/to/sample.bam \
  --pod5_dir /path/to/pod5_files/ \
  --log_level DEBUG \
  --outdir results/example7/

# ============================================================================
# Example 8: Resume failed run
# ============================================================================
echo "Example 8: Resume after failure"
nextflow run main.nf \
  -resume \
  --bam_input /path/to/bam_files/ \
  --pod5_dir /path/to/pod5_files/ \
  --outdir results/example8/

# ============================================================================
# Validation: Check output BAM files
# ============================================================================
echo "Validating output..."
samtools quickcheck results/example1/tagged/*.bam && echo "BAMs OK"
samtools view results/example1/tagged/*.bam | head -3
