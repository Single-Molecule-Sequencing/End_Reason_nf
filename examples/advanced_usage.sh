#!/bin/bash

#
# Advanced Usage Examples for End_Reason_nf Pipeline
#

# ============================================================================
# Example 1: Large-scale batch processing with POD5 caching
# ============================================================================
echo "Large-scale processing with caching..."

# Step 1: Extract POD5 metadata once
nextflow run main.nf \
  --bam_input batch1/sample1.bam \
  --pod5_dir /large/pod5/directory/ \
  --write_pod5_json cached_pod5_metadata.json \
  --outdir results/batch1/

# Step 2: Process remaining BAMs using cached metadata (much faster)
for batch in batch2 batch3 batch4; do
  echo "Processing $batch..."
  nextflow run main.nf \
    --bam_input ${batch}/*.bam \
    --pod5_json cached_pod5_metadata.json \
    --outdir results/${batch}/
done

# ============================================================================
# Example 2: Pipeline with custom resource allocation
# ============================================================================
echo "Custom resource allocation..."

# Edit nextflow.config or use command-line overrides
nextflow run main.nf \
  --bam_input large_dataset/*.bam \
  --pod5_dir pod5_files/ \
  --outdir results/custom_resources/ \
  -process.cpus 8 \
  -process.memory '16 GB'

# ============================================================================
# Example 3: Generate execution reports
# ============================================================================
echo "Generate detailed execution reports..."

nextflow run main.nf \
  --bam_input /path/to/bams/ \
  --pod5_dir /path/to/pod5/ \
  --outdir results/with_reports/ \
  -with-report execution_report.html \
  -with-timeline timeline.html \
  -with-dag flowchart.html \
  -with-trace

# ============================================================================
# Example 4: Integration with other pipelines
# ============================================================================
echo "Integration example: Tag BAMs then analyze..."

# Step 1: Tag with End_Reason_nf
nextflow run main.nf \
  --bam_input raw_bams/*.bam \
  --pod5_dir pod5_files/ \
  --outdir tagged_bams/

# Step 2: Use tagged BAMs in downstream analysis
# (e.g., with nanopore_analyzer package)
cd ../end_reason_ont
nanopore_analyzer \
  --bam_input ../End_Reason_nf/tagged_bams/tagged/*.bam \
  --outdir analysis_results/ \
  --interactive

# ============================================================================
# Example 5: Processing specific end_reason categories
# ============================================================================
echo "Extract and process specific end reasons..."

# Tag all BAMs
nextflow run main.nf \
  --bam_input all_bams/*.bam \
  --pod5_dir pod5_files/ \
  --outdir all_tagged/

# Extract signal_negative reads for further analysis
samtools view -h all_tagged/tagged/sample.endtag.bam | \
  awk '/^@/ || /ER:Z:SIGNAL_NEGATIVE/' | \
  samtools view -b -o signal_negative_only.bam

# ============================================================================
# Example 6: Quality control pipeline
# ============================================================================
echo "QC pipeline with end_reason tagging..."

# Tag BAMs
nextflow run main.nf \
  --bam_input sequencing_run/*.bam \
  --pod5_dir pod5_files/ \
  --outdir qc_tagged/

# Generate QC metrics
for bam in qc_tagged/tagged/*.bam; do
  echo "=== QC for $(basename $bam) ==="

  # Count reads by end_reason
  samtools view $bam | \
    grep -o 'ER:Z:[^[:space:]]*' | \
    sort | uniq -c | sort -rn

  # Check quality distribution
  samtools view $bam | \
    grep -o 'AQ:f:[^[:space:]]*' | \
    cut -d: -f3 | \
    awk '{sum+=$1; count++} END {print "Mean AQ:", sum/count}'

  # Check P5 coverage
  total=$(samtools view -c $bam)
  with_pod5=$(samtools view $bam | grep -c 'P5:i:1')
  echo "POD5 coverage: $with_pod5 / $total"
done

# ============================================================================
# Example 7: Parallel processing across compute nodes
# ============================================================================
echo "Distributed processing on HPC..."

# Create a sample sheet
cat > samples.csv << EOF
sample_id,bam_path
sample1,/data/bams/sample1.bam
sample2,/data/bams/sample2.bam
sample3,/data/bams/sample3.bam
EOF

# Process in parallel (example for SLURM)
nextflow run main.nf \
  -profile slurm \
  --bam_input /data/bams/*.bam \
  --pod5_dir /data/pod5/ \
  --outdir /results/parallel/ \
  -qs 10  # Max 10 jobs in queue

# ============================================================================
# Example 8: Resuming failed runs with different parameters
# ============================================================================
echo "Resume with modified parameters..."

# Initial run (might fail or be interrupted)
nextflow run main.nf \
  --bam_input large_dataset/*.bam \
  --pod5_dir pod5_files/ \
  --outdir results/resume_test/

# Resume with more resources if it failed
nextflow run main.nf \
  -resume \
  --bam_input large_dataset/*.bam \
  --pod5_dir pod5_files/ \
  --outdir results/resume_test/ \
  -process.memory '32 GB'

# ============================================================================
# Example 9: Comprehensive validation of results
# ============================================================================
echo "Comprehensive output validation..."

OUTDIR="results/validation/"

# Check all BAMs are valid
find $OUTDIR/tagged/ -name "*.bam" | \
  xargs samtools quickcheck && \
  echo "✓ All BAMs pass quickcheck"

# Verify all BAMs have indexes
for bam in $OUTDIR/tagged/*.bam; do
  if [ ! -f "${bam}.bai" ]; then
    echo "✗ Missing index for $bam"
  fi
done

# Check tag completeness
for bam in $OUTDIR/tagged/*.bam; do
  echo "Checking $(basename $bam)..."

  total=$(samtools view -c $bam)
  p5_tags=$(samtools view $bam | grep -c 'P5:i:')
  aq_tags=$(samtools view $bam | grep -c 'AQ:f:')
  le_tags=$(samtools view $bam | grep -c 'LE:i:')

  echo "  Total reads: $total"
  echo "  P5 tags: $p5_tags"
  echo "  AQ tags: $aq_tags"
  echo "  LE tags: $le_tags"

  if [ $total -eq $p5_tags ] && [ $total -eq $aq_tags ] && [ $total -eq $le_tags ]; then
    echo "  ✓ All reads properly tagged"
  else
    echo "  ✗ Missing tags detected!"
  fi
done

# ============================================================================
# Example 10: Extract statistics for publication
# ============================================================================
echo "Generate publication-ready statistics..."

TAGGED_DIR="results/publication/tagged/"

# Create statistics report
{
  echo "# End Reason Analysis Statistics"
  echo ""
  echo "## Sample Information"
  echo "Date: $(date)"
  echo "Total BAM files: $(ls $TAGGED_DIR/*.bam | wc -l)"
  echo ""

  for bam in $TAGGED_DIR/*.bam; do
    sample=$(basename $bam .endtag.bam)
    echo "## Sample: $sample"
    echo ""

    total=$(samtools view -c $bam)
    echo "Total reads: $total"
    echo ""

    echo "### End Reason Distribution"
    samtools view $bam | \
      grep -o 'ER:Z:[^[:space:]]*' | \
      cut -d: -f3 | \
      sort | uniq -c | \
      awk -v total=$total '{printf "- %s: %d (%.2f%%)\n", $2, $1, 100*$1/total}'
    echo ""

    echo "### Quality Metrics"
    avg_q=$(samtools view $bam | \
      grep -o 'AQ:f:[^[:space:]]*' | \
      cut -d: -f3 | \
      awk '{sum+=$1; count++} END {printf "%.2f", sum/count}')
    echo "- Mean quality score: $avg_q"

    avg_len=$(samtools view $bam | \
      grep -o 'LE:i:[^[:space:]]*' | \
      cut -d: -f3 | \
      awk '{sum+=$1; count++} END {printf "%.0f", sum/count}')
    echo "- Mean read length: ${avg_len} bp"
    echo ""
  done
} > publication_statistics.md

echo "Statistics saved to publication_statistics.md"
