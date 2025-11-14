# CLAUDE.md - AI Assistant Guide for End_Reason_nf

**Last Updated**: 2025-11-14
**Repository**: https://github.com/Single-Molecule-Sequencing/End_Reason_nf
**Purpose**: Guide for AI assistants working with this codebase

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Core Architecture](#core-architecture)
4. [Development Workflow](#development-workflow)
5. [Key Files Reference](#key-files-reference)
6. [Common Tasks](#common-tasks)
7. [Coding Conventions](#coding-conventions)
8. [Testing Strategy](#testing-strategy)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Important Context](#important-context)

---

## Project Overview

### What This Project Does

End_Reason_nf is a **Nextflow pipeline** that tags BAM files with end_reason metadata extracted from Oxford Nanopore POD5 files. It enriches sequencing reads with:

- **End reasons** (SIGNAL_POSITIVE, SIGNAL_NEGATIVE, etc.)
- **Quality metrics** (average Phred quality)
- **POD5 metadata** (channel, samples, timestamps)
- **Computed flags** (POD5 data availability)

### Technology Stack

- **Nextflow DSL2** (workflow orchestration)
- **Python 3.11** (core tagging logic)
- **pysam 0.22** (BAM file manipulation)
- **pod5** (POD5 file reading)
- **samtools 1.20** (BAM validation/indexing)
- **Docker/Conda** (environment management)
- **GitHub Actions** (CI/CD)

### Key Concepts

1. **POD5 Files**: Oxford Nanopore Technology's raw signal data format
2. **End Reasons**: Why a sequencing read terminated (normal, blocked pore, etc.)
3. **BAM Tags**: Custom SAM/BAM tags (ER, ZE, P5, AQ, LE, NS, CH, SS)
4. **POD5 JSON Caching**: Pre-extract POD5 metadata for 10x+ speedup

---

## Repository Structure

```
End_Reason_nf/
├── .github/                    # GitHub configuration
│   ├── workflows/              # CI/CD workflows
│   │   ├── ci.yml              # Continuous integration (lint, test, validate)
│   │   ├── docker-build.yml    # Docker image building
│   │   └── release.yml         # Automated releases
│   ├── ISSUE_TEMPLATE/         # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md
│
├── bin/                        # Executable scripts
│   └── tag_end_reason.py       # Core Python tagging script (298 lines)
│
├── envs/                       # Conda environments
│   └── tagger.yaml             # Python dependencies
│
├── examples/                   # Usage examples
│   ├── basic_usage.sh          # 8 basic examples
│   └── advanced_usage.sh       # 10 advanced examples
│
├── test_data/                  # Test data documentation
│   └── README.md
│
├── main.nf                     # Main Nextflow pipeline (221 lines)
├── nextflow.config             # Nextflow configuration (152 lines)
├── nextflow_schema.json        # JSON schema for parameters
├── workflow.toml               # EPI2ME Desktop metadata
├── output_definition.json      # Output schema
├── Dockerfile                  # Container definition
│
├── README.md                   # User documentation
├── INSTALLATION.md             # Setup guide
├── QUICK_START.md              # Quick reference
├── CONTRIBUTING.md             # Contributor guide
├── CHANGELOG.md                # Version history
├── PROJECT_SUMMARY.md          # Complete project overview
├── IMPORT_SUMMARY.md           # Import evaluation
├── GITHUB_SETUP.md             # Repository setup
├── EPI2ME_INTEGRATION.md       # EPI2ME Desktop integration
├── EPI2ME_TROUBLESHOOTING.md   # EPI2ME troubleshooting
│
├── test_pipeline.sh            # Test script
├── LICENSE                     # MIT License
├── .gitignore                  # Git ignore rules
├── .dockerignore               # Docker ignore rules
├── 2me.json                    # EPI2ME metadata
├── epi2me.json                 # EPI2ME metadata (symlink)
└── wf-end-reason.2me           # EPI2ME workflow definition
```

### Directory Purposes

- **bin/**: Executable scripts called by Nextflow processes
- **envs/**: Conda environment definitions
- **examples/**: Runnable usage examples
- **test_data/**: Test data references and documentation
- **.github/**: GitHub-specific configuration (Actions, templates)

---

## Core Architecture

### Nextflow Pipeline Flow

```
main.nf workflow:
  1. Parameter validation
  2. Channel creation (BAM files)
  3. Process: TAG_END_REASON
     - Input: BAM file + POD5 data
     - Script: bin/tag_end_reason.py
     - Output: Tagged BAM + index + summary
  4. Completion reporting
```

### Process: TAG_END_REASON

**File**: `main.nf:129-169`

**Resources**:
- CPUs: 2 (standard), 4 (SLURM)
- Memory: 4 GB (standard), 8 GB (SLURM)
- Time: 2h (standard), 4h (SLURM)

**Error Handling**:
- Strategy: Retry up to 2 times
- Validation: `samtools quickcheck` on output
- Indexing: Automatic with `samtools index`

**Outputs**:
- `${sample_id}.endtag.bam` - Tagged BAM file
- `${sample_id}.endtag.bam.bai` - BAM index
- `${sample_id}.endtag.summary.tsv` - Summary statistics

### Python Script: tag_end_reason.py

**File**: `bin/tag_end_reason.py`

**Key Functions**:

1. **`read_pod5_files(pod5_path)`** (line 48)
   - Reads POD5 files from directory or single file
   - Extracts metadata: end_reason, channel, samples, timestamps
   - Returns: Dict[read_id -> metadata]

2. **`extract_channel_from_pore(pore_info)`** (line 39)
   - Parses channel number from POD5 pore object
   - Uses regex to extract from string representation

3. **Main tagging logic**:
   - Reads input BAM with pysam
   - Matches reads to POD5 data by read_id
   - Calculates quality metrics (Phred formula)
   - Adds 8 custom tags to each read
   - Writes output BAM with same header

### BAM Tags Added

| Tag | Type | SAM Spec | Description | Example |
|-----|------|----------|-------------|---------|
| ER  | Z (string) | ER:Z:VALUE | End reason | ER:Z:SIGNAL_POSITIVE |
| ZE  | Z (string) | ZE:Z:VALUE | End reason (explicit string) | ZE:Z:SIGNAL_POSITIVE |
| P5  | i (int) | P5:i:VALUE | POD5 data found (1=yes, 0=no) | P5:i:1 |
| AQ  | f (float) | AQ:f:VALUE | Average quality (Phred) | AQ:f:12.34 |
| LE  | i (int) | LE:i:VALUE | Read length (bp) | LE:i:1523 |
| NS  | i (int) | NS:i:VALUE | Number of samples | NS:i:12345 |
| CH  | i (int) | CH:i:VALUE | Channel number | CH:i:42 |
| SS  | i (int) | SS:i:VALUE | Start sample | SS:i:100000 |

### End Reason Values

**Normalization**: All end_reason strings normalized to uppercase

1. **SIGNAL_POSITIVE** - Normal read completion through pore
2. **SIGNAL_NEGATIVE** - Large negative current (pore blockage)
3. **UNBLOCK_MUX_CHANGE** - Strand blocked pore, voltage reversal triggered
4. **DATA_SERVICE_UNBLOCK_MUX_CHANGE** - Active ejection via adaptive sampling
5. **MUX_CHANGE** - Routine multiplexer scan
6. **ANALYSIS_CONFIG_CHANGE** - Analysis configuration changed during run

**Mapping Logic** (bin/tag_end_reason.py:78-93):
```python
# Case-insensitive matching with priority order
if "signal_positive" in end_reason_str:
    end_reason = "SIGNAL_POSITIVE"
elif "signal_negative" in end_reason_str:
    end_reason = "SIGNAL_NEGATIVE"
# ... (see script for full logic)
```

---

## Development Workflow

### Setting Up Development Environment

```bash
# 1. Clone repository
git clone https://github.com/Single-Molecule-Sequencing/End_Reason_nf.git
cd End_Reason_nf

# 2. Create conda environment
conda env create -f envs/tagger.yaml
conda activate tagger

# 3. Verify installation
python --version  # Should be 3.11
python -c "import pysam, pod5, pandas"
samtools --version  # Should be 1.20

# 4. Test pipeline
./test_pipeline.sh
```

### Branch Strategy

- **main**: Production-ready code, protected
- **develop**: Integration branch (not currently used)
- **feature/**: New features (`feature/add-new-tag`)
- **fix/**: Bug fixes (`fix/pod5-parsing-error`)
- **claude/**: Claude-generated branches (auto-created by bot)

### Making Changes

```bash
# 1. Create feature branch
git checkout -b feature/your-feature

# 2. Make changes (follow conventions below)

# 3. Test locally
./test_pipeline.sh
nextflow run main.nf --help

# 4. Lint code
flake8 bin/*.py --max-line-length=100
black --check bin/*.py

# 5. Commit with clear messages
git add .
git commit -m "Add: feature description

- Detail 1
- Detail 2
- Detail 3"

# 6. Push and create PR
git push origin feature/your-feature
```

### Pull Request Process

1. **Fill out PR template** (.github/PULL_REQUEST_TEMPLATE.md)
2. **Wait for CI checks** (lint, validate, test, documentation)
3. **Address review comments**
4. **Merge** (squash and merge preferred)

---

## Key Files Reference

### main.nf (221 lines)

**Purpose**: Main Nextflow pipeline definition

**Key Sections**:
- **Lines 1-19**: Header documentation
- **Lines 21**: Enable DSL2
- **Lines 23-32**: Parameter definitions
- **Lines 37-87**: Help message function
- **Lines 92-108**: Parameter validation
- **Lines 113-124**: Parameter summary logging
- **Lines 129-169**: TAG_END_REASON process
- **Lines 174-202**: Main workflow
- **Lines 204-220**: Completion/error handlers

**Important Variables**:
- `params.bam_input` - Required BAM file or directory
- `params.pod5_dir` - Optional POD5 directory
- `params.pod5_json` - Optional pre-extracted POD5 JSON
- `params.outdir` - Output directory (default: ./results)
- `params.write_pod5_json` - Path to save POD5 JSON cache
- `params.log_level` - Python logging level (default: INFO)

**Channel Creation Logic** (lines 176-192):
```groovy
// Handles both single file and directory inputs
if (bam_path.isFile()) {
    // Single file: [sample_id, file]
    bam_ch = Channel.of([sample_id, bam_path])
} else if (bam_path.isDirectory()) {
    // Directory: map each BAM to [sample_id, file]
    bam_ch = Channel.fromPath("${params.bam_input}/*.bam")
        .map { bam_file -> [bam_file.baseName, bam_file] }
}
```

### nextflow.config (152 lines)

**Purpose**: Nextflow configuration and profiles

**Key Sections**:
- **Lines 6-14**: Manifest (metadata)
- **Lines 17-28**: Default parameters
- **Lines 31-42**: Process configuration
- **Lines 45-49**: Executor settings
- **Lines 52-56**: Conda settings
- **Lines 59-65**: Docker settings
- **Lines 68-126**: Profile definitions
- **Lines 129-151**: Report configuration

**Profiles**:

1. **standard** (default)
   - Executor: local
   - Container: Docker (ghcr.io/single-molecule-sequencing/end-reason-nf:latest)
   - Resources: 2 CPUs, 4 GB RAM

2. **docker**
   - Same as standard (explicit Docker usage)

3. **conda**
   - Executor: local
   - Environment: envs/tagger.yaml
   - Conda enabled instead of Docker

4. **local**
   - Same as conda (explicit local execution)

5. **slurm**
   - Executor: SLURM
   - Queue: standard
   - Account: atheylab
   - Resources: 4 CPUs, 8 GB RAM, 4h time limit
   - Environment: Conda (envs/tagger.yaml)

6. **test**
   - Minimal resources for testing
   - Resources: 1 CPU, 2 GB RAM, 30m time limit

### bin/tag_end_reason.py (298 lines)

**Purpose**: Core Python script for BAM tagging

**Key Features**:
- POD5 reading with pod5 library
- BAM manipulation with pysam
- Quality calculation using Phred formula
- JSON caching for performance
- Comprehensive logging

**Command-line Arguments**:
```
--in-bam PATH          Input BAM file (required)
--out-bam PATH         Output BAM file (required)
--pod5-dir PATH        POD5 directory (optional)
--pod5-json PATH       Pre-extracted POD5 JSON (optional)
--write-pod5-json PATH Save POD5 metadata to JSON (optional)
--log-level LEVEL      Logging level (default: INFO)
```

**Usage in Nextflow**:
```bash
${projectDir}/bin/tag_end_reason.py \
    --in-bam ${bam} \
    --out-bam ${sample_id}.endtag.bam \
    ${pod5_arg} \
    ${pod5_json_arg} \
    ${write_json_arg} \
    --log-level ${params.log_level} \
    > ${sample_id}.endtag.summary.tsv
```

### nextflow_schema.json (172 lines)

**Purpose**: JSON Schema for parameter validation and EPI2ME Desktop UI

**Key Sections**:
- **definitions/input**: Input parameters (bam_input, pod5_dir, pod5_json)
- **definitions/output**: Output parameters (outdir, write_pod5_json)
- **definitions/advanced**: Advanced options (log_level)
- **docs**: Documentation snippets for EPI2ME
- **resources**: Resource requirements

**Used By**:
- EPI2ME Desktop (form generation)
- Nextflow parameter validation
- Documentation generation

### Dockerfile (27 lines)

**Purpose**: Container definition for reproducible execution

**Base Image**: `mambaorg/micromamba:1.5.8`

**Steps**:
1. Copy conda environment file
2. Install dependencies with micromamba
3. Set environment variables
4. Verify installations

**Building**:
```bash
docker build -t end-reason-nf:latest .
```

**Usage**:
```bash
docker run -v $(pwd):/data end-reason-nf:latest \
    python /app/bin/tag_end_reason.py --help
```

---

## Common Tasks

### Running the Pipeline

**Basic usage**:
```bash
nextflow run main.nf \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  --outdir results/
```

**With POD5 JSON caching**:
```bash
# First run: extract and save POD5 metadata
nextflow run main.nf \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  --write_pod5_json pod5_metadata.json \
  --outdir results/

# Subsequent runs: use cached metadata (10x faster)
nextflow run main.nf \
  --bam_input other_sample.bam \
  --pod5_json pod5_metadata.json \
  --outdir results/
```

**SLURM execution**:
```bash
nextflow run main.nf \
  -profile slurm \
  --bam_input bam_directory/ \
  --pod5_dir pod5_files/ \
  --outdir results/
```

**With resume** (continue failed run):
```bash
nextflow run main.nf -resume \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  --outdir results/
```

**Generate reports**:
```bash
nextflow run main.nf \
  --bam_input sample.bam \
  --pod5_dir pod5_files/ \
  -with-report report.html \
  -with-timeline timeline.html \
  -with-trace trace.txt \
  -with-dag dag.html \
  --outdir results/
```

### Testing

**Run test suite**:
```bash
./test_pipeline.sh
```

**Test help message**:
```bash
nextflow run main.nf --help
```

**Test Python script**:
```bash
conda activate tagger
python bin/tag_end_reason.py --help
```

**Validate output**:
```bash
# Check BAM integrity
samtools quickcheck results/tagged/*.bam

# View tagged reads
samtools view results/tagged/sample.endtag.bam | head

# Check specific tags
samtools view results/tagged/sample.endtag.bam | \
  grep -oP "ER:Z:\w+" | sort | uniq -c
```

### Linting and Formatting

**Python**:
```bash
# Check style
flake8 bin/*.py --max-line-length=100 --extend-ignore=E203,W503

# Format code
black bin/*.py

# Check formatting without changes
black --check bin/*.py
```

**Nextflow**:
```bash
# Validate syntax
nextflow config main.nf

# Show available profiles
nextflow config main.nf -show-profiles
```

### Building Docker Image

```bash
# Build locally
docker build -t end-reason-nf:latest .

# Build for GitHub Container Registry
docker build -t ghcr.io/single-molecule-sequencing/end-reason-nf:latest .

# Push to registry
docker push ghcr.io/single-molecule-sequencing/end-reason-nf:latest
```

### Creating a Release

```bash
# 1. Update version in nextflow.config
# manifest.version = '1.1.0'

# 2. Update CHANGELOG.md with changes

# 3. Commit changes
git add nextflow.config CHANGELOG.md
git commit -m "Bump version to 1.1.0"

# 4. Create and push tag
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin main
git push origin v1.1.0

# 5. GitHub Actions will create release automatically
```

---

## Coding Conventions

### Python Code Style

**Standard**: PEP 8 with modifications

**Line Length**: 100 characters (not 80)

**Import Order**:
```python
# 1. Future imports
from __future__ import annotations

# 2. Standard library
import argparse
import json
import logging

# 3. Third-party
import pod5
import pysam

# 4. Local (if any)
from .utils import helper
```

**Type Hints**: Required for function signatures
```python
def read_pod5_files(pod5_path: str) -> Dict[str, Dict[str, object]]:
    """Read POD5 files and return metadata."""
    ...
```

**Docstrings**: Google style
```python
def extract_channel_from_pore(pore_info) -> int:
    """Extract the channel number from a POD5 pore metadata object.

    Args:
        pore_info: POD5 pore metadata object

    Returns:
        Channel number as integer

    Raises:
        ValueError: If channel cannot be extracted
    """
    ...
```

**Logging**: Use logging module, not print
```python
import logging
LOG = logging.getLogger(__name__)

# Usage
LOG.info("Processing %d files", file_count)
LOG.debug("Read ID: %s", read_id)
LOG.warning("Missing POD5 data for read %s", read_id)
LOG.error("Failed to process file: %s", error)
```

**Error Handling**: Explicit exceptions
```python
# Good
if not os.path.exists(path):
    raise FileNotFoundError(f"POD5 file not found: {path}")

# Bad
if not os.path.exists(path):
    print(f"Error: file not found {path}")
    return None
```

### Nextflow Code Style

**DSL Version**: DSL2 (required)
```groovy
nextflow.enable.dsl=2
```

**Process Naming**: UPPERCASE_SNAKE_CASE
```groovy
process TAG_END_REASON {
    ...
}
```

**Process Tags**: Use sample ID for tracking
```groovy
process TAG_END_REASON {
    tag { sample_id }  // Shows in logs as [sample_id]
    ...
}
```

**Parameter Access**: Use params.* in workflow, not in process
```groovy
// Good - in workflow block
def pod5_arg = params.pod5_dir ? "--pod5-dir '${params.pod5_dir}'" : ""

// Bad - don't use params in process script directly
process BAD_EXAMPLE {
    script:
    """
    tool --input ${params.bam_input}  // Don't do this
    """
}
```

**Script Safety**: Use bash strict mode
```groovy
script:
"""
set -euo pipefail  // Exit on error, undefined vars, pipe failures

${projectDir}/bin/tag_end_reason.py \\
    --in-bam ${bam} \\
    --out-bam ${sample_id}.endtag.bam
"""
```

**Channel Handling**: Explicit tuple structure
```groovy
// Good - clear structure
tuple val(sample_id), path(bam)

// Map operations
.map { bam_file ->
    def sample_id = bam_file.baseName
    [sample_id, bam_file]
}
```

### Documentation Style

**Markdown**: GitHub-flavored

**Code Blocks**: Always specify language
```markdown
```bash
nextflow run main.nf --help
\```

```python
import pysam
\```
```

**Headings**: ATX style (# headings), not Setext (underlines)
```markdown
# Good
## Good

Bad
===
```

**Links**: Use reference-style for repeated links
```markdown
See the [documentation][docs] for details.
More info in the [documentation][docs].

[docs]: https://github.com/Single-Molecule-Sequencing/End_Reason_nf
```

### Commit Messages

**Format**:
```
Type: Short description (50 chars or less)

- Detailed point 1
- Detailed point 2
- Detailed point 3

Fixes #123
```

**Types**:
- `Add:` New feature
- `Fix:` Bug fix
- `Update:` Enhancement to existing feature
- `Docs:` Documentation only
- `Refactor:` Code restructuring
- `Test:` Test additions/changes
- `Chore:` Maintenance tasks

**Examples**:
```
Add: POD5 JSON caching for faster reruns

- Implement --write-pod5-json parameter
- Add --pod5-json parameter to use cached data
- Update documentation with caching examples
- Provides 10x+ speedup for multiple BAM files

Fixes #42
```

```
Fix: Channel extraction regex for new POD5 format

- Update regex pattern to handle channel=XXX format
- Add test case for new POD5 version
- Log warning for unrecognized formats

Fixes #56
```

---

## Testing Strategy

### Test Levels

1. **Unit Tests**: Python functions (pytest)
2. **Integration Tests**: Pipeline execution (test_pipeline.sh)
3. **CI Tests**: Automated in GitHub Actions

### Test Script: test_pipeline.sh

**Location**: Repository root

**What it tests**:
- Help message display
- Basic pipeline execution without POD5
- Tag presence in output BAM
- BAM file integrity
- Index file creation

**Usage**:
```bash
./test_pipeline.sh
```

**Expected Output**:
```
Testing End Reason Tagger Pipeline...
✓ Help message displayed
✓ Pipeline executed without POD5
✓ Output BAM created
✓ BAM integrity verified
✓ Tags present in output
All tests passed!
```

### CI/CD Tests

**Workflow**: `.github/workflows/ci.yml`

**Jobs**:

1. **lint**: Code style and syntax
   - Python: flake8, black
   - Nextflow: config validation

2. **validate**: Configuration validation
   - Nextflow config parsing
   - Conda environment creation
   - Package imports

3. **test**: Pipeline execution
   - Help message test
   - Python script test
   - Dependencies: lint, validate

4. **documentation**: Documentation checks
   - Required files present
   - Markdown link validation

5. **release-check**: Release readiness (main branch only)
   - Version extraction
   - Tag status check

### Running Tests Locally

**All tests**:
```bash
./test_pipeline.sh
```

**Python linting**:
```bash
flake8 bin/*.py --max-line-length=100
black --check bin/*.py
```

**Nextflow validation**:
```bash
nextflow config main.nf
nextflow config main.nf -show-profiles
```

**Conda environment**:
```bash
conda env create -f envs/tagger.yaml --name test-env
conda activate test-env
python -c "import pysam, pod5, pandas; print('OK')"
conda deactivate
conda env remove -n test-env
```

### Test Data

**Location**: `test_data/` directory (documentation only)

**Actual data**: Not included in repository (too large)

**References**:
- See `test_data/README.md` for data locations
- Test data typically from Nanopore sequencing runs
- POD5 files require ~GB of space

---

## CI/CD Pipeline

### GitHub Actions Workflows

**Location**: `.github/workflows/`

### Workflow: CI (.github/workflows/ci.yml)

**Triggers**:
- Push to main or develop branches
- Pull requests to main or develop
- Manual trigger (workflow_dispatch)

**Jobs**:

1. **lint**
   - Runner: ubuntu-latest
   - Python version: 3.11
   - Steps: Install flake8/black, lint Python, validate Nextflow

2. **validate**
   - Runner: ubuntu-latest
   - Steps: Install Nextflow, validate config, check conda environment

3. **test** (depends on lint, validate)
   - Runner: ubuntu-latest
   - Steps: Test help message, test Python script

4. **documentation**
   - Runner: ubuntu-latest
   - Steps: Check required docs exist, validate markdown links

5. **release-check** (main branch only, depends on test, documentation)
   - Runner: ubuntu-latest
   - Steps: Check version in config, verify tag status

**Exit Codes**:
- 0: Success
- 1: Failure (stops workflow)

### Workflow: Docker Build (.github/workflows/docker-build.yml)

**Triggers**:
- Push to main branch
- Version tags (v*.*.*)
- Manual trigger

**Steps**:
1. Checkout code
2. Set up Docker Buildx
3. Login to GitHub Container Registry
4. Build and push image
5. Tag with version and latest

**Image Tags**:
- `latest`: Latest main branch
- `v1.0.0`: Specific version tags

### Workflow: Release (.github/workflows/release.yml)

**Triggers**:
- Version tags only (v*.*.*)

**Steps**:
1. Checkout code with full history
2. Extract version from tag
3. Parse CHANGELOG.md for release notes
4. Create GitHub release with notes
5. Upload release assets (if any)

**Release Notes**: Extracted from CHANGELOG.md between version headers

### Status Badges

Add to README.md:
```markdown
[![CI](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/actions/workflows/ci.yml/badge.svg)](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/actions/workflows/ci.yml)
```

---

## Important Context

### For AI Assistants Working on This Codebase

#### Project History

1. **Original Author**: kmathew
2. **Source**: `kmathew/nextflow_implementation/your-pipeline`
3. **Import Date**: 2025-11-12
4. **Importer**: gregfar
5. **Organization**: Single-Molecule-Sequencing

**Attribution**: Always maintain attribution to kmathew in documentation and code headers.

#### Design Decisions

**Why Nextflow?**
- Workflow orchestration for HPC environments
- Reproducibility with containers/conda
- Resume capability for long-running jobs
- Integration with SLURM and other schedulers

**Why Python?**
- pysam for BAM manipulation
- pod5 library for POD5 reading
- Pandas for data handling
- Easy integration with scientific Python ecosystem

**Why POD5 JSON Caching?**
- POD5 reading is expensive (minutes for large files)
- Multiple BAM files from same run share POD5 data
- Caching provides 10x+ speedup
- Trade-off: disk space for time

**Why 8 Different Tags?**
- Redundancy for compatibility (ER and ZE both store end_reason)
- Different tools expect different tag types
- Computed metrics (AQ, LE) useful for filtering
- P5 flag indicates data quality/completeness

#### Common Pitfalls

**1. POD5 File Reading**
- POD5 files can be large (GB+)
- May contain more/fewer reads than BAM
- Some reads in BAM may not be in POD5 (pre-filtered)
- Solution: Tag with P5=0 if no POD5 data

**2. Channel Extraction**
- POD5 pore objects don't have direct .channel attribute
- Must parse from string representation
- Solution: Regex extraction (see bin/tag_end_reason.py:39-45)

**3. Quality Score Calculation**
- Simple mean is incorrect for Phred scores
- Must use proper formula: -10 * log10(mean(10^(-q/10)))
- Solution: Implemented correctly in tag_end_reason.py

**4. Nextflow Channel Handling**
- Channels are consumed after use
- Cannot reuse channels without splitting
- Solution: Proper channel design in main.nf

**5. Docker vs Conda**
- Default is Docker (for EPI2ME Desktop compatibility)
- Some users prefer Conda (HPC environments)
- Solution: Multiple profiles in nextflow.config

#### File Modification Guidelines

**When modifying main.nf**:
1. Maintain DSL2 syntax
2. Update help message if parameters change
3. Update parameter validation logic
4. Test with `-profile test` first
5. Update nextflow_schema.json if parameters change

**When modifying bin/tag_end_reason.py**:
1. Maintain type hints
2. Update docstrings
3. Add logging for debugging
4. Handle exceptions gracefully
5. Test with and without POD5 data

**When modifying nextflow.config**:
1. Update all relevant profiles
2. Consider resource implications
3. Test profile switching
4. Document new parameters

**When modifying documentation**:
1. Keep README.md user-focused
2. Keep CONTRIBUTING.md developer-focused
3. Update CHANGELOG.md for user-visible changes
4. Update this CLAUDE.md for AI assistant context

#### Integration Context

**Parent Repository**: end_reason/

**Related Tools**:
- `nanopore_analyzer`: Complete analysis pipeline (Python package)
- This pipeline: Focused on BAM tagging only

**Workflow Integration**:
```bash
# 1. Tag with End_Reason_nf (this pipeline)
nextflow run main.nf --bam_input data.bam --pod5_dir pod5/ --outdir tagged/

# 2. Analyze with nanopore_analyzer (parent repo)
nanopore_analyzer --bam_input tagged/*.bam --outdir analysis/
```

**Complementary, Not Duplicate**:
- End_Reason_nf: Production Nextflow pipeline, HPC-ready, Docker/Conda
- nanopore_analyzer: Interactive analysis, visualization, web interface

#### EPI2ME Desktop Integration

**Purpose**: This pipeline is designed for Oxford Nanopore's EPI2ME Desktop application

**Key Files**:
- `workflow.toml`: EPI2ME metadata
- `nextflow_schema.json`: UI form generation
- `output_definition.json`: Output schema
- `2me.json`, `epi2me.json`, `wf-end-reason.2me`: EPI2ME manifests

**Docker Requirement**: EPI2ME Desktop requires Docker containers

**Default Profile**: `standard` profile uses Docker by default for EPI2ME compatibility

**See Also**:
- `EPI2ME_INTEGRATION.md`: Detailed EPI2ME integration guide
- `EPI2ME_TROUBLESHOOTING.md`: EPI2ME-specific issues

#### Performance Considerations

**Typical Runtime** (Intel Xeon, 4 CPUs, 8 GB RAM):
- Small BAM (1 GB): 5-10 minutes
- Medium BAM (10 GB): 30-60 minutes
- Large BAM (100 GB): 3-5 hours

**POD5 Reading** (one-time cost):
- 1000 POD5 files: ~5 minutes
- 10000 POD5 files: ~30 minutes
- With JSON caching: <1 second

**Scalability**:
- Linear with BAM size
- Parallel across multiple BAM files
- SLURM profile for large batches

**Memory Usage**:
- Baseline: ~1 GB
- +POD5 data in memory: +1-3 GB
- Peak: 4-8 GB (depending on BAM size)

#### Security Considerations

**Input Validation**:
- File paths validated before processing
- No shell injection (uses proper Nextflow quoting)
- No arbitrary code execution

**Docker Container**:
- Runs as non-root user
- Limited to required dependencies
- No network access needed

**Data Privacy**:
- All processing local
- No data sent to external services
- Logs may contain read IDs (avoid sharing publicly)

#### Troubleshooting Tips

**Pipeline fails immediately**:
- Check parameter syntax
- Verify file paths exist
- Check Nextflow version (>=21.04.0)

**POD5 reading fails**:
- Verify POD5 file format
- Check pod5 library version
- Try with single POD5 file first

**BAM tagging fails**:
- Check BAM file integrity (samtools quickcheck)
- Verify disk space
- Check file permissions

**Out of memory**:
- Reduce parallel jobs
- Increase memory in config
- Use SLURM profile with more resources

**Slow performance**:
- Use POD5 JSON caching
- Reduce log level to WARNING
- Check disk I/O (not network storage)

#### Version Compatibility

**Nextflow**: >=21.04.0 (tested up to 23.10.0)
**Python**: 3.11 (may work with 3.9-3.12)
**pysam**: 0.22.* (API changes in 0.23)
**samtools**: 1.20 (compatible with 1.15-1.21)
**pod5**: Latest (API stable as of 2025)

**Breaking Changes to Watch**:
- pysam API changes (major versions)
- pod5 format changes (rare)
- Nextflow DSL changes (DSL3 if released)

#### When to Edit This File

Update `CLAUDE.md` when:
1. Major architectural changes
2. New files or directories added
3. Workflow logic changes
4. New coding conventions adopted
5. Important context discovered
6. Common issues identified
7. Integration points change

**Keep this file current** - it's the first place AI assistants should look.

---

## Quick Reference

### Essential Commands

```bash
# Run pipeline
nextflow run main.nf --bam_input data.bam --pod5_dir pod5/ --outdir results/

# Run with resume
nextflow run main.nf -resume ...

# Run with specific profile
nextflow run main.nf -profile slurm ...

# Test pipeline
./test_pipeline.sh

# Validate configuration
nextflow config main.nf

# Get help
nextflow run main.nf --help
```

### Essential Files

| File | Purpose | Modify Frequency |
|------|---------|------------------|
| main.nf | Pipeline logic | Often |
| nextflow.config | Configuration | Sometimes |
| bin/tag_end_reason.py | Core script | Often |
| nextflow_schema.json | Parameter schema | When params change |
| README.md | User docs | Often |
| CLAUDE.md | This file | When context changes |

### Essential Concepts

| Concept | Description | Key File |
|---------|-------------|----------|
| POD5 | Nanopore raw data format | bin/tag_end_reason.py |
| End Reason | Why read terminated | bin/tag_end_reason.py:78-93 |
| BAM Tags | Custom SAM/BAM annotations | bin/tag_end_reason.py:200-250 |
| JSON Cache | POD5 metadata caching | bin/tag_end_reason.py:48-120 |
| DSL2 | Nextflow workflow syntax | main.nf |
| Process | Nextflow execution unit | main.nf:129-169 |
| Profile | Environment configuration | nextflow.config:68-126 |

---

## Additional Resources

### External Documentation

- **Nextflow**: https://www.nextflow.io/docs/latest/
- **pysam**: https://pysam.readthedocs.io/
- **pod5**: https://github.com/nanoporetech/pod5-file-format
- **SAM/BAM format**: https://samtools.github.io/hts-specs/
- **EPI2ME Desktop**: https://labs.epi2me.io/

### Repository Documentation

- **README.md**: User guide and overview
- **INSTALLATION.md**: Setup instructions
- **QUICK_START.md**: Quick reference
- **CONTRIBUTING.md**: Contributor guide
- **PROJECT_SUMMARY.md**: Complete project overview
- **IMPORT_SUMMARY.md**: Import evaluation and history
- **GITHUB_SETUP.md**: Repository setup guide
- **EPI2ME_INTEGRATION.md**: EPI2ME Desktop integration
- **EPI2ME_TROUBLESHOOTING.md**: EPI2ME troubleshooting

### Contact

- **Issues**: https://github.com/Single-Molecule-Sequencing/End_Reason_nf/issues
- **Discussions**: GitHub Discussions
- **Original Author**: kmathew
- **Maintainer**: Single-Molecule-Sequencing organization

---

**End of CLAUDE.md** - Last updated: 2025-11-14
