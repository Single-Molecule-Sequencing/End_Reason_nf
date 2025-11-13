# Contributing to End_Reason_nf

Thank you for your interest in contributing to the Nextflow End Reason Tagger pipeline!

## Repository

- **GitHub**: https://github.com/Single-Molecule-Sequencing/End_Reason_nf.git
- **Organization**: Single-Molecule-Sequencing

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/Single-Molecule-Sequencing/End_Reason_nf.git
cd End_Reason_nf
```

### Set Up Development Environment

```bash
# Create conda environment
conda env create -f envs/tagger.yaml
conda activate tagger

# Verify installation
./test_pipeline.sh
```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 2. Make Changes

- Follow the existing code style
- Update documentation as needed
- Add tests for new features
- Ensure all tests pass

### 3. Test Your Changes

```bash
# Run test suite
./test_pipeline.sh

# Test with real data
nextflow run main.nf \
  --bam_input test.bam \
  --pod5_dir pod5_files/ \
  --outdir test_results/

# Validate output
samtools quickcheck test_results/tagged/*.bam
```

### 4. Commit Changes

Use clear, descriptive commit messages:

```bash
git add .
git commit -m "Add feature: description of change

- Detail 1
- Detail 2
- Detail 3"
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Code Style Guidelines

### Python Code

- Follow PEP 8
- Use type hints where applicable
- Add docstrings to functions
- Use Python logging module (not print)
- Handle exceptions gracefully

Example:
```python
def process_data(input_path: str) -> Dict[str, Any]:
    """Process input data and return results.

    Args:
        input_path: Path to input file

    Returns:
        Dictionary containing processed results

    Raises:
        FileNotFoundError: If input file doesn't exist
    """
    LOG.info("Processing data from %s", input_path)
    # ... implementation
```

### Nextflow Code

- Use DSL2 syntax
- Document process inputs/outputs
- Add meaningful process tags
- Use appropriate error strategies

Example:
```groovy
process PROCESS_NAME {
    tag { sample_id }
    publishDir "${params.outdir}/output", mode: 'copy'

    input:
    tuple val(sample_id), path(input_file)

    output:
    tuple val(sample_id), path("${sample_id}.output")

    script:
    """
    # Clear, commented script
    process_tool --input ${input_file} --output ${sample_id}.output
    """
}
```

### Documentation

- Update README.md for user-facing changes
- Update INSTALLATION.md for setup changes
- Keep QUICK_START.md concise
- Document breaking changes prominently

## Testing Requirements

### Before Submitting a PR

- [ ] All existing tests pass
- [ ] New features have tests
- [ ] Documentation is updated
- [ ] No unnecessary files committed
- [ ] Commit messages are clear

### Test Checklist

```bash
# 1. Run automated tests
./test_pipeline.sh

# 2. Test help message
nextflow run main.nf --help

# 3. Test without POD5
nextflow run main.nf --bam_input test.bam --outdir test1/

# 4. Test with POD5 (if available)
nextflow run main.nf --bam_input test.bam --pod5_dir pod5/ --outdir test2/

# 5. Validate output
samtools quickcheck test*/tagged/*.bam
samtools view test*/tagged/*.bam | head -1
```

## Pull Request Guidelines

### PR Title

Use descriptive titles:
- `Add: Feature description`
- `Fix: Bug description`
- `Update: Component being updated`
- `Docs: Documentation update`

### PR Description

Include:
- **What**: What does this PR do?
- **Why**: Why is this change needed?
- **How**: How does it work?
- **Testing**: How was it tested?
- **Breaking Changes**: Any breaking changes?

Example:
```markdown
## What
Add support for multi-sample POD5 processing

## Why
Users need to process multiple samples in a single run

## How
- Modified POD5 reader to accept sample IDs
- Updated channel creation logic
- Added multi-sample test

## Testing
Tested with 10 samples, all processed successfully

## Breaking Changes
None
```

## Issue Reporting

### Bug Reports

Include:
- Pipeline version or commit hash
- Command used
- Expected behavior
- Actual behavior
- Error messages
- System information (OS, Nextflow version)

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative solutions considered
- Impact on existing functionality

## Release Process

### Version Numbering

We use [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

### Creating a Release

1. Update version in `nextflow.config`
2. Update CHANGELOG.md
3. Create git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push tag: `git push origin v1.0.0`
5. Create GitHub release with notes

## Project Structure

```
End_Reason_nf/
├── bin/                    # Executable scripts
│   └── tag_end_reason.py
├── envs/                   # Conda environments
│   └── tagger.yaml
├── test_data/              # Test data documentation
│   └── README.md
├── docs/                   # Additional documentation
├── main.nf                 # Main pipeline
├── nextflow.config         # Configuration
├── test_pipeline.sh        # Test script
├── .gitignore             # Git ignore rules
├── README.md              # User documentation
├── INSTALLATION.md        # Setup guide
├── QUICK_START.md         # Quick reference
├── IMPORT_SUMMARY.md      # Import history
└── CONTRIBUTING.md        # This file
```

## Communication

- **Issues**: Use GitHub Issues for bugs and features
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact repository maintainers

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Acknowledge contributions

## Attribution

This pipeline was imported from kmathew/nextflow_implementation/your-pipeline and is maintained by the Single-Molecule-Sequencing organization.

### Original Authors
- kmathew (original implementation)

### Contributors
Contributors will be listed in GitHub's contributor graph and acknowledged in releases.

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Questions?

- Open an issue on GitHub
- Check existing documentation
- Contact maintainers

Thank you for contributing! 🎉
