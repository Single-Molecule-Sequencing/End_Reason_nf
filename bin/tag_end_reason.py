#!/usr/bin/env python3
"""Tag reads in a BAM with POD5 end-reason metadata.

This script exposes the notebook-developed helpers behind a simple CLI so it can
be orchestrated by Nextflow. Two arguments are required:

    --in-bam   Path to an input BAM file or folder containing BAMs
    --out-bam  Output BAM destination (file or directory depending on the input)

Optional arguments allow the caller to provide POD5 data as raw files or as a
pre-rendered JSON blob:

    --pod5-dir     Directory (or single file) of POD5 reads to mine metadata from
    --pod5-json    JSON file previously written by ``--write-pod5-json`` or similar
    --write-pod5-json  Persist the extracted POD5 table to this JSON path for reuse

If no POD5 data are supplied, the script still copies reads and annotates them
with basic metrics (mean quality, length) while marking ``P5=0`` to signal the
absence of POD5 enrichment.
"""

from __future__ import annotations

import argparse
import glob
import json
import logging
import math
import os
import re
from collections import Counter
from typing import Dict, Iterable, List
import pod5
import pysam

LOG = logging.getLogger(__name__)


def extract_channel_from_pore(pore_info) -> int:
    """Extract the channel number from a POD5 pore metadata object."""
    pore_str = str(pore_info)
    match = re.search(r"channel=(\d+)", pore_str)
    if match:
        return int(match.group(1))
    raise ValueError(f"Could not extract channel from pore info: {pore_info}")


def read_pod5_files(pod5_path: str) -> Dict[str, Dict[str, object]]:
    """Read POD5 files and summarise end-reason metadata by read ID."""
    read_id_to_info: Dict[str, Dict[str, object]] = {}
    total_reads = 0

    if os.path.isdir(pod5_path):
        LOG.info("Scanning POD5 directory: %s", pod5_path)
        pod5_files = [
            os.path.join(pod5_path, f)
            for f in os.listdir(pod5_path)
            if f.endswith(".pod5") or f.endswith(".pod5.gz")
        ]
        if not pod5_files:
            raise ValueError(f"No POD5 files found in directory: {pod5_path}")
        LOG.info("Found %d POD5 files", len(pod5_files))
    else:
        if not os.path.exists(pod5_path):
            raise FileNotFoundError(f"POD5 file not found: {pod5_path}")
        LOG.info("Reading POD5 file: %s", pod5_path)
        pod5_files = [pod5_path]

    for pod5_file in pod5_files:
        try:
            LOG.debug("Processing POD5 file: %s", pod5_file)
            with pod5.Reader(pod5_file) as reader:
                file_reads = 0
                for read in reader:
                    total_reads += 1
                    file_reads += 1
                    read_id = str(read.read_id)
                    end_reason_str = str(read.end_reason).lower()

                    if "signal_positive" in end_reason_str:
                        end_reason = "SIGNAL_POSITIVE"
                    elif "signal_negative" in end_reason_str:
                        end_reason = "SIGNAL_NEGATIVE"
                    elif "data_service_unblock_mux_change" in end_reason_str:
                        end_reason = "DATA_SERVICE_UNBLOCK_MUX_CHANGE"
                    elif "unblock_mux_change" in end_reason_str:
                        end_reason = "UNBLOCK_MUX_CHANGE"
                    elif "mux_change" in end_reason_str and "unblock" not in end_reason_str:
                        end_reason = "MUX_CHANGE"
                    elif "analysis_config_change" in end_reason_str:
                        end_reason = "ANALYSIS_CONFIG_CHANGE"
                    else:
                        end_reason = end_reason_str

                    channel = extract_channel_from_pore(read.pore)

                    read_id_to_info[read_id] = {
                        "end_reason": end_reason,
                        "num_samples": read.num_samples,
                        "start_sample": read.start_sample,
                        "channel": channel,
                    }

                LOG.info(
                    "%-40s : %5d reads",
                    os.path.basename(pod5_file),
                    file_reads,
                )

        except Exception as exc:  # pragma: no cover - diagnostic only
            LOG.warning("Error reading POD5 file %s: %s", pod5_file, exc)
            continue

    if total_reads == 0:
        raise ValueError("No reads found in any POD5 files.")

    end_reason_counts = Counter(info["end_reason"] for info in read_id_to_info.values())
    LOG.info("End reason breakdown:")
    for reason, count in end_reason_counts.most_common():
        LOG.info("  %s: %d (%.2f%%)", reason, count, 100 * count / total_reads)

    LOG.info("Total POD5 reads processed: %d", total_reads)
    return read_id_to_info


def calculate_average_quality(quality_scores: Iterable[int]) -> float | None:
    """Compute the average base quality using the log-sum formula."""
    scores = list(quality_scores)
    if not scores:
        return None
    phred_sum = sum(10 ** (-q / 10) for q in scores)
    return -10 * math.log10(phred_sum / len(scores))


def add_tags_to_bam(
    input_path: str,
    pod5_data: Dict[str, Dict[str, object]],
    output_path: str,
) -> List[str]:
    """Annotate reads in one or more BAMs with POD5-derived metadata."""
    output_files: List[str] = []

    if os.path.isfile(input_path):
        bam_files = [input_path]
        if os.path.isdir(output_path):
            basename = os.path.basename(input_path)
            output_paths = [os.path.join(output_path, basename)]
            os.makedirs(output_path, exist_ok=True)
        else:
            output_paths = [output_path]
            outdir = os.path.dirname(output_path)
            if outdir:
                os.makedirs(outdir, exist_ok=True)
    elif os.path.isdir(input_path):
        os.makedirs(output_path, exist_ok=True)
        bam_files = glob.glob(os.path.join(input_path, "*.bam"))
        output_paths = [os.path.join(output_path, os.path.basename(bam)) for bam in bam_files]
    else:
        raise ValueError(f"Input path '{input_path}' is neither a file nor a directory")

    reads_with_pod5 = 0
    reads_without_pod5 = 0
    total_reads_processed = 0

    for bam_file, output_file_path in zip(bam_files, output_paths):
        input_read_count = 0
        with pysam.AlignmentFile(bam_file, "rb", check_sq=False) as in_bam:
            for _ in in_bam:
                input_read_count += 1

        LOG.info("Processing %s (%d reads)", os.path.basename(bam_file), input_read_count)

        reads_written = 0
        read_ids_seen = set()

        with pysam.AlignmentFile(bam_file, "rb", check_sq=False) as in_bam:
            with pysam.AlignmentFile(output_file_path, "wb", header=in_bam.header, check_sq=False) as out_bam:
                for read in in_bam:
                    read_id = read.query_name
                    if read_id in read_ids_seen and not read.is_paired:
                        LOG.debug("Duplicate read ID encountered: %s", read_id)
                    elif read.is_paired:
                        LOG.debug("Paired read encountered: %s", read_id)
                    read_ids_seen.add(read_id)

                    total_reads_processed += 1
                    reads_written += 1

                    if read.query_qualities:
                        avg_quality = calculate_average_quality(read.query_qualities)
                        if avg_quality is not None:
                            read.set_tag("AQ", round(avg_quality, 2))

                    if read.query_sequence:
                        read.set_tag("LE", len(read.query_sequence))

                    if read_id in pod5_data:
                        info = pod5_data[read_id]
                        read.set_tag("ER", info["end_reason"])
                        read.set_tag("ZE", info["end_reason"], value_type='Z')
                        read.set_tag("NS", info["num_samples"])
                        read.set_tag("CH", info["channel"])
                        read.set_tag("SS", info["start_sample"])
                        read.set_tag("P5", 1)
                        reads_with_pod5 += 1
                    else:
                        read.set_tag("ZE", "NO_POD5", value_type='Z')
                        read.set_tag("P5", 0)
                        reads_without_pod5 += 1

                    out_bam.write(read)

        LOG.info("Wrote %d reads to %s", reads_written, output_file_path)
        output_files.append(output_file_path)

    if not bam_files:
        LOG.warning("No BAM files found in %s", input_path)
    else:
        LOG.info("Total BAM files processed: %d", len(output_files))
        LOG.info("Reads with POD5 data: %d", reads_with_pod5)
        LOG.info("Reads without POD5 data: %d", reads_without_pod5)
        LOG.info("Total reads processed: %d", total_reads_processed)

    return output_files


def load_pod5_json(path: str) -> Dict[str, Dict[str, object]]:
    """Load POD5 metadata previously exported to JSON."""
    with open(path, "r", encoding="utf-8") as handle:
        records = json.load(handle)
    if isinstance(records, dict):
        return records
    if isinstance(records, list):
        return {record["read_id"]: {k: v for k, v in record.items() if k != "read_id"} for record in records}
    raise ValueError(f"Unexpected JSON structure in {path}")


def write_pod5_json(path: str, pod5_data: Dict[str, Dict[str, object]]) -> None:
    """Persist POD5 metadata for reuse, mirroring the notebook helper."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(
            [
                {"read_id": read_id, **info}
                for read_id, info in pod5_data.items()
            ],
            handle,
            indent=2,
        )
    LOG.info("Wrote POD5 metadata table: %s", path)


def parse_args(argv: List[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--in-bam", required=True, help="Input BAM file or directory")
    parser.add_argument("--out-bam", required=True, help="Output BAM file or directory")
    parser.add_argument("--pod5-dir", help="Directory (or single file) containing POD5 reads")
    parser.add_argument("--pod5-json", help="JSON file holding pre-extracted POD5 metadata")
    parser.add_argument(
        "--write-pod5-json",
        help="Optional path to write the extracted POD5 metadata as JSON",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        help="Logging verbosity (default: INFO)",
    )
    return parser.parse_args(argv)


def main(argv: List[str] | None = None) -> int:
    args = parse_args(argv)
    logging.basicConfig(level=getattr(logging, args.log_level), format="%(levelname)s: %(message)s")

    pod5_data: Dict[str, Dict[str, object]]
    if args.pod5_json:
        LOG.info("Loading POD5 metadata from JSON: %s", args.pod5_json)
        pod5_data = load_pod5_json(args.pod5_json)
    elif args.pod5_dir:
        pod5_data = read_pod5_files(args.pod5_dir)
        if args.write_pod5_json:
            write_pod5_json(args.write_pod5_json, pod5_data)
    else:
        LOG.warning("No POD5 data provided; reads will be tagged with P5=0 only.")
        pod5_data = {}

    output_files = add_tags_to_bam(args.in_bam, pod5_data, args.out_bam)
    LOG.info("Generated %d BAM file(s)", len(output_files))
    for path in output_files:
        LOG.info("  -> %s", path)

    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
