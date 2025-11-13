#!/usr/bin/env nextflow

/*
 * Nextflow Pipeline: Tag BAM Files with POD5 End Reason Metadata
 *
 * This pipeline processes BAM files and adds end_reason metadata tags from POD5 files.
 * It adds the following tags to each read:
 * - ER: End reason from POD5 (e.g., SIGNAL_POSITIVE, SIGNAL_NEGATIVE)
 * - ZE: End reason as string type
 * - NS: Number of samples from POD5
 * - CH: Channel number from POD5
 * - SS: Start sample from POD5
 * - P5: POD5 data present flag (1=yes, 0=no)
 * - AQ: Average quality score (calculated using proper Phred formula)
 * - LE: Read length
 *
 * Imported from kmathew/nextflow_implementation/your-pipeline
 * Date: 2025-11-12
 */

nextflow.enable.dsl=2

/*
 * Pipeline parameters
 */
params.pod5_dir = null
params.pod5_json = null
params.bam_input = null
params.outdir = "./results"
params.write_pod5_json = null
params.log_level = "INFO"
params.help = false

/*
 * Help message
 */
def helpMessage() {
    log.info"""
    ================================================================================
    Tag BAM with POD5 End Reason Metadata Pipeline
    ================================================================================

    Usage:
      nextflow run main.nf --pod5_dir <POD5_DIR> --bam_input <BAM_FILE_OR_DIR> --outdir <OUTPUT_DIR>

    Required arguments:
      --bam_input       Path to a BAM file or directory containing BAM files

    POD5 input (one of the following):
      --pod5_dir        Path to directory containing POD5 files (or single POD5 file)
      --pod5_json       Path to pre-extracted POD5 metadata JSON file

    Optional arguments:
      --outdir          Output directory for tagged BAM files (default: ./results)
      --write_pod5_json Path to save extracted POD5 metadata as JSON for reuse
      --log_level       Logging level: DEBUG, INFO, WARNING, ERROR, CRITICAL (default: INFO)
      --help            Show this help message

    Examples:
      # Process a single BAM file with POD5 directory
      nextflow run main.nf \\
        --pod5_dir /path/to/pod5_files \\
        --bam_input /path/to/sample.bam \\
        --outdir /path/to/output

      # Process multiple BAM files from a directory
      nextflow run main.nf \\
        --pod5_dir /path/to/pod5_files \\
        --bam_input /path/to/bam_files \\
        --outdir /path/to/output

      # Use pre-extracted POD5 JSON for faster processing
      nextflow run main.nf \\
        --pod5_json /path/to/pod5_metadata.json \\
        --bam_input /path/to/bam_files \\
        --outdir /path/to/output

      # Extract POD5 metadata and save for reuse
      nextflow run main.nf \\
        --pod5_dir /path/to/pod5_files \\
        --bam_input /path/to/sample.bam \\
        --write_pod5_json /path/to/save_metadata.json \\
        --outdir /path/to/output

    ================================================================================
    """.stripIndent()
}

/*
 * Show help message if requested
 */
if (params.help) {
    helpMessage()
    exit 0
}

/*
 * Validate required parameters
 */
if (!params.bam_input) {
    log.error "ERROR: --bam_input parameter is required"
    helpMessage()
    exit 1
}

if (!params.pod5_dir && !params.pod5_json) {
    log.warn "WARNING: Neither --pod5_dir nor --pod5_json provided. Reads will be tagged with P5=0 only."
}

/*
 * Print parameter summary
 */
log.info ""
log.info "================================================================================"
log.info "Tag BAM with POD5 End Reason Metadata Pipeline"
log.info "================================================================================"
log.info "BAM input         : ${params.bam_input}"
log.info "POD5 directory    : ${params.pod5_dir ?: 'Not provided'}"
log.info "POD5 JSON         : ${params.pod5_json ?: 'Not provided'}"
log.info "Output directory  : ${params.outdir}"
log.info "Write POD5 JSON   : ${params.write_pod5_json ?: 'No'}"
log.info "Log level         : ${params.log_level}"
log.info "================================================================================"
log.info ""

/*
 * Process: Tag BAM files with POD5 end_reason metadata
 */
process TAG_END_REASON {
    tag { sample_id }
    publishDir "${params.outdir}/tagged", mode: 'copy', overwrite: true
    // conda directive removed - uses Docker by default (see nextflow.config)
    cpus 2
    memory '4 GB'
    errorStrategy 'retry'
    maxRetries 2

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}.endtag.bam"), path("${sample_id}.endtag.bam.bai"), emit: tagged_bam
    path "${sample_id}.endtag.summary.tsv", emit: summary

    script:
    def pod5_arg = params.pod5_dir ? "--pod5-dir '${params.pod5_dir}'" : ""
    def pod5_json_arg = params.pod5_json ? "--pod5-json '${params.pod5_json}'" : ""
    def write_json_arg = params.write_pod5_json ? "--write-pod5-json '${params.write_pod5_json}'" : ""
    """
    set -euo pipefail

    ${projectDir}/bin/tag_end_reason.py \\
        --in-bam ${bam} \\
        --out-bam ${sample_id}.endtag.bam \\
        ${pod5_arg} \\
        ${pod5_json_arg} \\
        ${write_json_arg} \\
        --log-level ${params.log_level} \\
        > ${sample_id}.endtag.summary.tsv

    # Validate output BAM file
    samtools quickcheck -v ${sample_id}.endtag.bam

    # Index the output BAM file
    samtools index -@ ${task.cpus} ${sample_id}.endtag.bam

    echo "TAG_END_REASON\t${sample_id}\tOK" >&2
    """
}

/*
 * Workflow
 */
workflow {
    // Create channel for BAM files
    def bam_path = file(params.bam_input)

    if (bam_path.isFile()) {
        // Single BAM file - extract sample ID from filename
        def sample_id = bam_path.baseName.replaceAll(/\.bam$/, '')
        bam_ch = Channel.of([sample_id, bam_path])
    } else if (bam_path.isDirectory()) {
        // Directory of BAM files
        bam_ch = Channel
            .fromPath("${params.bam_input}/*.bam", checkIfExists: true)
            .map { bam_file ->
                def sample_id = bam_file.baseName.replaceAll(/\.bam$/, '')
                [sample_id, bam_file]
            }
    } else {
        error "ERROR: --bam_input must be a valid file or directory: ${params.bam_input}"
    }

    // Run tagging process
    TAG_END_REASON(bam_ch)

    // Emit completion messages
    TAG_END_REASON.out.tagged_bam.subscribe {
        sample_id, bam, bai ->
        log.info "Tagged BAM file created: ${bam}"
    }
}

workflow.onComplete {
    log.info ""
    log.info "================================================================================"
    log.info "Pipeline completed at: ${workflow.complete}"
    log.info "Duration            : ${workflow.duration}"
    log.info "Success             : ${workflow.success}"
    log.info "Exit status         : ${workflow.exitStatus}"
    log.info "Output directory    : ${params.outdir}"
    log.info "================================================================================"
}

workflow.onError {
    log.error "================================================================================"
    log.error "Pipeline execution failed!"
    log.error "Error message: ${workflow.errorMessage}"
    log.error "================================================================================"
}
