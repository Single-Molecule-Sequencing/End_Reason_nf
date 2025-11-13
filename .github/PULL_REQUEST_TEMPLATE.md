# Pull Request

## Description

Briefly describe what this PR does.

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Test addition or modification
- [ ] Configuration change

## Related Issue

Fixes #(issue number)
Relates to #(issue number)

## Changes Made

List the specific changes made in this PR:

- Change 1
- Change 2
- Change 3

## Testing

Describe how you tested your changes:

- [ ] Tested with sample data
- [ ] Ran `./test_pipeline.sh`
- [ ] Tested help message: `nextflow run main.nf --help`
- [ ] Tested without POD5 data
- [ ] Tested with POD5 data
- [ ] Tested on HPC/SLURM
- [ ] Validated output BAM files
- [ ] All existing tests pass
- [ ] Added new tests

### Test Commands Used

```bash
# Commands you ran to test this PR
nextflow run main.nf \
  --bam_input test.bam \
  --pod5_dir pod5_files/ \
  --outdir test_results/
```

### Test Results

```
# Paste test output or summary
```

## Checklist

- [ ] My code follows the style guidelines (PEP 8 for Python, DSL2 for Nextflow)
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have updated the documentation (README, INSTALLATION, etc.)
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
- [ ] Any dependent changes have been merged and published

## Documentation Updates

- [ ] README.md updated
- [ ] INSTALLATION.md updated
- [ ] QUICK_START.md updated
- [ ] CHANGELOG.md updated
- [ ] Code comments added/updated
- [ ] No documentation changes needed

## Breaking Changes

If this PR introduces breaking changes, describe them and the migration path:

**Breaking Changes:**
- None

**Migration Guide:**
- N/A

## Screenshots (if applicable)

Add screenshots or output examples to help explain your changes.

## Performance Impact

Describe any performance implications:

- [ ] No performance impact
- [ ] Performance improvement (describe)
- [ ] Performance degradation (describe and justify)

## Additional Notes

Any additional information reviewers should know:

---

## Reviewer Notes

**For reviewers:**
- Check that tests pass
- Verify documentation is updated
- Ensure code style is consistent
- Validate the change solves the stated problem
- Check for potential edge cases
