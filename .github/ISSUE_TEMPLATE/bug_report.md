---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## To Reproduce

Steps to reproduce the behavior:

1. Command used: `nextflow run main.nf ...`
2. Input files: (describe your BAM/POD5 files)
3. Configuration: (profile used, parameters)
4. Error observed: (error message or unexpected output)

## Expected Behavior

A clear description of what you expected to happen.

## Actual Behavior

What actually happened instead.

## Error Messages

```
Paste any error messages here
```

## Environment

- **OS**: [e.g., Ubuntu 20.04, CentOS 7, macOS]
- **Nextflow version**: [e.g., 21.04.3]
- **Pipeline version/commit**: [e.g., v1.0.0 or commit hash]
- **Execution profile**: [standard, local, slurm, test]
- **Conda version**: [e.g., 4.12.0]
- **Python version**: [from `python --version`]

## Input Data Details

- BAM file size: [e.g., 500 MB]
- POD5 directory size: [e.g., 2 GB]
- Number of reads: [approximate]
- Sequencing run type: [e.g., MinION, PromethION]

## Logs

<details>
<summary>Nextflow log (.nextflow.log)</summary>

```
Paste relevant parts of .nextflow.log here
```

</details>

<details>
<summary>Process log (work/.../command.log)</summary>

```
Paste relevant process logs here
```

</details>

## Additional Context

Add any other context about the problem here, such as:
- Does it work with different data?
- Did it work in a previous version?
- Any workarounds you've tried?

## Possible Solution

(Optional) If you have ideas on how to fix this, describe them here.
