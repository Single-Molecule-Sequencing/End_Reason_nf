#!/bin/bash

#
# Test script for Nextflow End Reason Tagger Pipeline
#

set -e

echo "========================================================================"
echo "Nextflow End Reason Tagger - Test Suite"
echo "========================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="$(pwd)/test_results"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_result="${3:-0}"  # Default: expect success (0)

    echo "========================================================================"
    echo "TEST: $test_name"
    echo "========================================================================"
    echo "Command: $test_cmd"
    echo ""

    if eval "$test_cmd"; then
        actual_result=0
    else
        actual_result=$?
    fi

    if [ "$actual_result" -eq "$expected_result" ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $test_name (exit code: $actual_result, expected: $expected_result)"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Test 1: Help message
run_test "Display help message" \
    "nextflow run main.nf --help"

# Test 2: Test without POD5 data (should still work, tags with P5=0)
echo "========================================================================"
echo "TEST 2: Process BAM without POD5 data"
echo "========================================================================"
echo ""

if [ -f "../end_reason_ont/signal_positive.bam" ]; then
    echo "Using test BAM: ../end_reason_ont/signal_positive.bam"

    # Run pipeline
    nextflow run main.nf \
        --bam_input ../end_reason_ont/signal_positive.bam \
        --outdir "$TEST_DIR/test_no_pod5" \
        --log_level INFO

    # Validate output
    if [ -f "$TEST_DIR/test_no_pod5/tagged/signal_positive.endtag.bam" ]; then
        echo -e "${GREEN}✓ Tagged BAM created${NC}"

        # Check BAM integrity
        if samtools quickcheck "$TEST_DIR/test_no_pod5/tagged/signal_positive.endtag.bam"; then
            echo -e "${GREEN}✓ BAM file is valid${NC}"

            # Check for tags
            echo ""
            echo "Sample tags from output BAM:"
            samtools view "$TEST_DIR/test_no_pod5/tagged/signal_positive.endtag.bam" | \
                head -1 | \
                awk '{for(i=12;i<=NF;i++){if($i~/^(P5|AQ|LE|ZE):/)print "  "$i}}'

            # Verify P5=0 (no POD5 data)
            if samtools view "$TEST_DIR/test_no_pod5/tagged/signal_positive.endtag.bam" | \
               head -1 | grep -q "P5:i:0"; then
                echo -e "${GREEN}✓ P5=0 tag verified (no POD5 data as expected)${NC}"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}✗ P5 tag not found or incorrect${NC}"
                ((TESTS_FAILED++))
            fi

            # Check for AQ and LE tags
            if samtools view "$TEST_DIR/test_no_pod5/tagged/signal_positive.endtag.bam" | \
               head -1 | grep -q "AQ:f:" && \
               samtools view "$TEST_DIR/test_no_pod5/tagged/signal_positive.endtag.bam" | \
               head -1 | grep -q "LE:i:"; then
                echo -e "${GREEN}✓ AQ and LE tags present${NC}"
            else
                echo -e "${YELLOW}⚠ AQ or LE tags missing${NC}"
            fi
        else
            echo -e "${RED}✗ BAM file validation failed${NC}"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "${RED}✗ Tagged BAM not created${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠ Test BAM not found, skipping test${NC}"
fi

echo ""

# Test 3: Check for POD5 files (optional test)
echo "========================================================================"
echo "TEST 3: Check for POD5 test data (optional)"
echo "========================================================================"
echo ""

POD5_TEST_DIR=$(find .. -type d -name "pod5*" 2>/dev/null | head -1)
if [ -n "$POD5_TEST_DIR" ] && [ -d "$POD5_TEST_DIR" ]; then
    echo "Found POD5 directory: $POD5_TEST_DIR"
    POD5_COUNT=$(find "$POD5_TEST_DIR" -name "*.pod5" 2>/dev/null | wc -l)
    echo "POD5 files found: $POD5_COUNT"

    if [ "$POD5_COUNT" -gt 0 ]; then
        echo -e "${GREEN}To test with POD5 data, run:${NC}"
        echo "  nextflow run main.nf \\"
        echo "    --bam_input ../end_reason_ont/signal_positive.bam \\"
        echo "    --pod5_dir $POD5_TEST_DIR \\"
        echo "    --outdir test_results/with_pod5"
    fi
else
    echo "No POD5 test data found in parent directory"
    echo "To test with POD5 data, you need to provide a POD5 directory:"
    echo "  nextflow run main.nf \\"
    echo "    --bam_input ../end_reason_ont/signal_positive.bam \\"
    echo "    --pod5_dir /path/to/pod5 \\"
    echo "    --outdir test_results/with_pod5"
fi

echo ""

# Summary
echo "========================================================================"
echo "TEST SUMMARY"
echo "========================================================================"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
