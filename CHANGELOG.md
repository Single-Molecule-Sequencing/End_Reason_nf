# Changelog

All notable changes to the End_Reason_nf pipeline will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- GitHub Actions CI/CD integration
- Automated testing on multiple platforms
- Performance benchmarking suite
- Multi-sample batch processing optimization

## [1.0.0] - 2025-11-12

### Added
- Initial release of End_Reason_nf pipeline
- Import from kmathew/nextflow_implementation/your-pipeline
- Nextflow DSL2 pipeline for BAM tagging with POD5 metadata
- Python script (`tag_end_reason.py`) for end_reason extraction and tagging
- Conda environment specification for dependency management
- Multiple execution profiles (standard, local, slurm, test)
- Comprehensive documentation:
  - README.md with full usage guide
  - INSTALLATION.md with setup instructions
  - QUICK_START.md for quick reference
  - IMPORT_SUMMARY.md with evaluation details
  - CONTRIBUTING.md with contribution guidelines
  - GITHUB_SETUP.md with repository setup docs
- Automated test script (`test_pipeline.sh`)
- Test data documentation
- GitHub issue and PR templates
- GitHub Actions workflows for CI/CD and releases
- MIT License with attribution

### Features
- Tag BAM files with end_reason metadata from POD5 files
- Support for POD5 JSON caching for improved performance
- Automatic calculation of quality scores (AQ) and read length (LE)
- Graceful handling of missing POD5 data (P5=0 flag)
- BAM validation with samtools quickcheck
- Automatic BAM indexing
- Support for single files or directories
- Parallel processing capability
- Multiple execution profiles for different environments

### Tags Added
- `ER:Z:` - End reason (uppercase normalized)
- `ZE:Z:` - End reason (explicit string type)
- `P5:i:` - POD5 data present flag (1=yes, 0=no)
- `AQ:f:` - Average quality score (Phred formula)
- `LE:i:` - Read length
- `NS:i:` - Number of samples (POD5)
- `CH:i:` - Channel number (POD5)
- `SS:i:` - Start sample (POD5)

### End Reasons Supported
- `SIGNAL_POSITIVE` - Normal pore completion
- `SIGNAL_NEGATIVE` - Large negative current drop (blockage)
- `UNBLOCK_MUX_CHANGE` - Voltage reversal triggered
- `DATA_SERVICE_UNBLOCK_MUX_CHANGE` - Adaptive sampling ejection
- `MUX_CHANGE` - Routine multiplexer scan
- `ANALYSIS_CONFIG_CHANGE` - Config change during run

## Attribution

### Original Implementation
- **Author**: kmathew
- **Source**: kmathew/nextflow_implementation/your-pipeline
- **Date**: 2025 (original)

### Import and Adaptation
- **Imported by**: gregfar
- **Date**: 2025-11-12
- **Organization**: Single-Molecule-Sequencing
- **Repository**: https://github.com/Single-Molecule-Sequencing/End_Reason_nf

## Version History

### Version 1.0.0 (2025-11-12)
- Initial public release
- Full production-ready pipeline
- Comprehensive documentation
- GitHub repository setup
- CI/CD workflows configured

---

## Upcoming Versions

### [1.1.0] - Planned
- Enhanced error reporting
- Additional quality metrics
- Performance optimizations
- Extended test suite

### [2.0.0] - Future
- Multi-sample support
- Advanced filtering options
- Integration with other pipelines
- Web interface for results

---

## How to Use This Changelog

- **[Unreleased]**: Changes in development
- **[Version]**: Released versions with date
- **Added**: New features
- **Changed**: Changes to existing features
- **Deprecated**: Features to be removed
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security updates

## Links

- [GitHub Releases](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/releases)
- [GitHub Issues](https://github.com/Single-Molecule-Sequencing/End_Reason_nf/issues)
- [Contributing Guide](CONTRIBUTING.md)
