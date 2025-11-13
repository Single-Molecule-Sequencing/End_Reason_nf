# Nextflow End Reason Tagger Pipeline

## Overview

This Nextflow pipeline tags BAM files with end_reason metadata extracted from Oxford Nanopore POD5 files. It was imported from `../kmathew/nextflow_implementation/your-pipeline` on 2025-11-12.

## Pipeline Evaluation

### Source Analysis

Two implementations were found in the kmathew directory:

1. **Simple Implementation** (`tag_bam.nf`):
   - Standalone single-process pipeline
   - Uses `tag_bam_with_pod5.py` script
   - More verbose logging with print statements
   - Good for quick tagging tasks

2. **Modular Implementation** (`your-pipeline/`):
   - Structured with separate workflow and module files
   - Uses `tag_end_reason.py` script (✓ **Selected for import**)
   - Professional Python logging
   - Support for POD5 JSON caching
   - Better error handling and documentation
   - More production-ready

### Tags Added to BAM Files

The pipeline adds the following tags to each read:

| Tag | Type | Description | Source |
|-----|------|-------------|--------|
| `ER` | String | End reason (normalized uppercase) | POD5 |
| `ZE` | String | End reason (string type, explicit) | POD5 |
| `NS` | Integer | Number of samples | POD5 |
| `CH` | Integer | Channel number | POD5 |
| `SS` | Integer | Start sample | POD5 |
| `P5` | Integer | POD5 data present flag (1=yes, 0=no) | Computed |
| `AQ` | Float | Average quality score (Phred formula) | Computed from BAM |
| `LE` | Integer | Read length | Computed from BAM |

### End Reason Values

The pipeline normalizes end_reason strings to uppercase:

- `SIGNAL_POSITIVE` - Normal completion through the pore
- `SIGNAL_NEGATIVE` - Large negative current drop (typically pore blockage)
- `UNBLOCK_MUX_CHANGE` - Strand blocked pore, voltage reversal triggered
- `DATA_SERVICE_UNBLOCK_MUX_CHANGE` - Active ejection via adaptive sampling
- `MUX_CHANGE` - Routine multiplexer scan
- `ANALYSIS_CONFIG_CHANGE` - Analysis configuration changed during run

### Quality Score Calculation

Average quality (`AQ`) is calculated using the proper Phred formula:

```
AQ = -10 * log10(sum(10^(-q/10)) / |q|)
```

This gives a more accurate representation than simple arithmetic mean.

## Requirements

### Software Dependencies

- Nextflow >= 21.04.0
- Conda or Mamba (for environment management)
- Python 3.11
- pysam 0.22.*
- samtools 1.20
- pod5 (Python package)
- pandas

### Installation

The pipeline uses conda to manage dependencies automatically. The environment is defined in `envs/tagger.yaml`.

## Usage

### Basic Usage

```bash
# Process a single BAM file
nextflow run main.nf \
  --pod5_dir /path/to/pod5_files \
  --bam_input /path/to/sample.bam \
  --outdir /path/to/output

# Process multiple BAM files from a directory
nextflow run main.nf \
  --pod5_dir /path/to/pod5_files \
  --bam_input /path/to/bam_files \
  --outdir /path/to/output
```

### Advanced Usage

```bash
# Use pre-extracted POD5 JSON for faster processing
nextflow run main.nf \
  --pod5_json /path/to/pod5_metadata.json \
  --bam_input /path/to/bam_files \
  --outdir /path/to/output

# Extract and save POD5 metadata for reuse
nextflow run main.nf \
  --pod5_dir /path/to/pod5_files \
  --bam_input /path/to/sample.bam \
  --write_pod5_json /path/to/save_metadata.json \
  --outdir /path/to/output

# Use SLURM profile for HPC execution
nextflow run main.nf \
  -profile slurm \
  --pod5_dir /path/to/pod5_files \
  --bam_input /path/to/bam_files \
  --outdir /path/to/output

# Enable debug logging
nextflow run main.nf \
  --pod5_dir /path/to/pod5_files \
  --bam_input /path/to/sample.bam \
  --log_level DEBUG \
  --outdir /path/to/output
```

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--bam_input` | Yes | - | Path to BAM file or directory of BAM files |
| `--pod5_dir` | No* | null | Path to POD5 file or directory of POD5 files |
| `--pod5_json` | No* | null | Path to pre-extracted POD5 metadata JSON |
| `--outdir` | No | ./results | Output directory for tagged BAM files |
| `--write_pod5_json` | No | null | Path to save POD5 metadata as JSON |
| `--log_level` | No | INFO | Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL) |
| `--help` | No | false | Show help message |

\* Either `--pod5_dir` or `--pod5_json` should be provided. If neither is given, reads will be tagged with `P5=0` only.

### Profiles

- `standard` (default) - Local execution with conda
- `local` - Explicit local execution
- `slurm` - SLURM HPC execution (configured for atheylab account)
- `test` - Test profile with minimal resources

## Output Structure

```
results/
├── tagged/
│   ├── sample1.endtag.bam       # Tagged BAM file
│   ├── sample1.endtag.bam.bai   # BAM index
│   ├── sample1.endtag.summary.tsv  # Summary statistics
│   └── ...
└── reports/
    ├── execution_report.html
    ├── timeline.html
    ├── trace.txt
    └── dag.html
```

## Implementation Details

### Pipeline Workflow

1. **Input Validation**: Checks for required parameters and validates file paths
2. **Channel Creation**: Creates Nextflow channels for BAM files (supports both single files and directories)
3. **POD5 Processing** (if provided):
   - Reads POD5 files to extract metadata
   - Normalizes end_reason strings
   - Extracts channel, sample counts, and timestamps
   - Optionally caches to JSON for reuse
4. **BAM Tagging**:
   - Reads each BAM file
   - Calculates quality and length metrics
   - Matches reads to POD5 metadata by read_id
   - Adds all tags to reads
   - Writes tagged BAM with same header
5. **Validation**: Runs `samtools quickcheck` on output
6. **Indexing**: Creates BAM index files

### Error Handling

- Retry strategy: Up to 2 retries on failure
- Graceful handling of missing POD5 data (tags with `P5=0`)
- Validation of output BAM files with samtools
- Comprehensive logging at multiple levels

### Performance Considerations

- Uses 2 CPUs and 4 GB RAM per process by default
- Can be scaled up with SLURM profile (4 CPUs, 8 GB RAM)
- POD5 JSON caching significantly speeds up multiple runs with same POD5 data
- Processes multiple BAM files in parallel

## Testing

See `test_data/README.md` for information about running tests with example data.

## Source Attribution

- **Original Author**: kmathew
- **Source Location**: `../kmathew/nextflow_implementation/your-pipeline`
- **Import Date**: 2025-11-12
- **Modifications**:
  - Consolidated into single main.nf file
  - Added comprehensive documentation
  - Enhanced parameter validation
  - Added test profile

## Integration with end_reason Repository

This pipeline complements the existing `nanopore_analyzer` package in this repository:

- **nanopore_analyzer**: Complete analysis pipeline (tagging + statistics + visualization)
- **Nextflow_End_Reason**: Focused Nextflow pipeline for BAM tagging only

Use this Nextflow pipeline when you:
- Need to tag BAMs as part of a larger Nextflow workflow
- Want to process large batches with parallel execution
- Need SLURM/HPC integration
- Prefer Nextflow's workflow management features

Use `nanopore_analyzer` package when you:
- Want complete analysis with plots and reports
- Need interactive Python/Jupyter interface
- Want web-based interface for file upload
- Need detailed quality score analysis

## Troubleshooting

### Common Issues

1. **Conda environment creation timeout**
   - Increase timeout in `nextflow.config`: `conda.createTimeout = '2 h'`

2. **Memory errors**
   - Increase memory in config or use SLURM profile
   - Process fewer BAM files at once

3. **Missing POD5 reads**
   - Some reads in BAM may not be in POD5 (pre-filtered, etc.)
   - Check `P5` tag: `0` means no POD5 data for that read

4. **Samtools quickcheck fails**
   - Output BAM is corrupted
   - Check disk space and file permissions
   - Review process logs for errors

## License

Inherits license from parent repository (MIT).

## Contact

For issues related to this pipeline, contact the repository maintainer.
For questions about the original implementation, contact kmathew.
