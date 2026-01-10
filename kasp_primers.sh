#!/bin/bash

# KASP Primer Design Script
# Designs allele-specific primers for SNP genotyping

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print functions
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Default parameters
FLANK_LENGTH=250
MODE=""
VCF_FILE=""
REGION_FILE=""
REF_FASTA=""
CHROM=""
START_POS=""
END_POS=""
OUTPUT_PREFIX=""

# Primer3 defaults
PRIMER_MIN_SIZE=18
PRIMER_OPT_SIZE=20
PRIMER_MAX_SIZE=25
PRIMER_MIN_TM=57.0
PRIMER_OPT_TM=60.0
PRIMER_MAX_TM=63.0
PRIMER_MIN_GC=40.0
PRIMER_MAX_GC=60.0
PRIMER_NUM_RETURN=3

# KASP-specific
USE_TAILS=false
TAIL_FAM="GAAGGTGACCAAGTTCATGCT"
TAIL_HEX="GAAGGTCGGAGTCAACGGATT"
SNP_OFFSET=0

# VCF filtering
MIN_QUAL=20
MIN_DEPTH=5
BIALLELIC_ONLY=true

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

MODE 1: VCF + Region
  -v FILE     VCF file
  -r FILE     Reference genome FASTA
  -c CHR      Chromosome
  -s INT      Start position
  -e INT      End position
  -o PREFIX   Output prefix

MODE 2: Position file (4 columns required: chr pos ref alt)
  -r FILE     Reference genome FASTA
  -f FILE     Position file
  -o PREFIX   Output prefix

Optional:
  -l INT              Flanking length [default: 250]
  --use-tails         Add fluorophore tails
  --snp-offset INT    SNP position from 3' end [default: 0]
  --min-qual FLOAT    Min QUAL [default: 20]
  --min-depth INT     Min DP [default: 5]
  --allow-multiallelic  Allow multi-allelic SNPs

Primer3 Parameters:
  --primer-size-min INT       [default: 18]
  --primer-size-opt INT       [default: 20]
  --primer-size-max INT       [default: 25]
  --primer-tm-min FLOAT       [default: 57.0]
  --primer-tm-opt FLOAT       [default: 60.0]
  --primer-tm-max FLOAT       [default: 63.0]
  --primer-gc-min FLOAT       [default: 40.0]
  --primer-gc-max FLOAT       [default: 60.0]
  --num-return INT            [default: 3]
EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v) VCF_FILE="$2"; MODE="VCF_REGION"; shift 2 ;;
        -f) REGION_FILE="$2"; MODE="REGION_FILE"; shift 2 ;;
        -r) REF_FASTA="$2"; shift 2 ;;
        -c) CHROM="$2"; shift 2 ;;
        -s) START_POS="$2"; shift 2 ;;
        -e) END_POS="$2"; shift 2 ;;
        -o) OUTPUT_PREFIX="$2"; shift 2 ;;
        -l) FLANK_LENGTH="$2"; shift 2 ;;
        --use-tails) USE_TAILS=true; shift ;;
        --snp-offset) SNP_OFFSET="$2"; shift 2 ;;
        --min-qual) MIN_QUAL="$2"; shift 2 ;;
        --min-depth) MIN_DEPTH="$2"; shift 2 ;;
        --allow-multiallelic) BIALLELIC_ONLY=false; shift ;;
        --primer-size-min) PRIMER_MIN_SIZE="$2"; shift 2 ;;
        --primer-size-opt) PRIMER_OPT_SIZE="$2"; shift 2 ;;
        --primer-size-max) PRIMER_MAX_SIZE="$2"; shift 2 ;;
        --primer-tm-min) PRIMER_MIN_TM="$2"; shift 2 ;;
        --primer-tm-opt) PRIMER_OPT_TM="$2"; shift 2 ;;
        --primer-tm-max) PRIMER_MAX_TM="$2"; shift 2 ;;
        --primer-gc-min) PRIMER_MIN_GC="$2"; shift 2 ;;
        --primer-gc-max) PRIMER_MAX_GC="$2"; shift 2 ;;
        --num-return) PRIMER_NUM_RETURN="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Validate inputs
[[ -z "$MODE" ]] && print_error "Must specify -v (VCF) or -f (position file)"
[[ -z "$REF_FASTA" ]] && print_error "Reference FASTA required (-r)"
[[ -z "$OUTPUT_PREFIX" ]] && print_error "Output prefix required (-o)"

if [[ "$MODE" == "VCF_REGION" ]]; then
    [[ -z "$VCF_FILE" ]] && print_error "VCF file required"
    [[ -z "$CHROM" ]] && print_error "Chromosome required (-c)"
    [[ -z "$START_POS" ]] && print_error "Start position required (-s)"
    [[ -z "$END_POS" ]] && print_error "End position required (-e)"
fi

if [[ "$MODE" == "REGION_FILE" ]]; then
    [[ -z "$REGION_FILE" ]] && print_error "Position file required"
fi

# Check dependencies
command -v samtools >/dev/null 2>&1 || print_error "samtools not found"
command -v primer3_core >/dev/null 2>&1 || print_error "primer3_core not found"

# Create work directory
WORK_DIR="${OUTPUT_PREFIX}_results"
mkdir -p "$WORK_DIR"

# Index FASTA
if [[ ! -f "${REF_FASTA}.fai" ]]; then
    print_info "Indexing FASTA..."
    samtools faidx "$REF_FASTA"
fi

# Initialize output file
OUTPUT_FILE="${OUTPUT_PREFIX}.txt"
echo -e "Primer_name\tChr\tPosition\tStart\tEnd\tType\tSequence\tLength\tTm\tGC_Percent\tAmplicon_Size\tOff_Target" > "$OUTPUT_FILE"

# Function to design KASP primers for a SNP
design_kasp() {
    local chr=$1
    local pos=$2
    local ref=$3
    local alt=$4
    local var_id=$5
    
    # KASP only works for SNPs
    if [[ ${#ref} -ne 1 ]] || [[ ${#alt} -ne 1 ]]; then
        return 1
    fi
    
    # Extract sequence
    local extract_start=$((pos - FLANK_LENGTH))
    local extract_end=$((pos + FLANK_LENGTH))
    [[ $extract_start -lt 1 ]] && extract_start=1
    
    samtools faidx "$REF_FASTA" "${chr}:${extract_start}-${extract_end}" 2>/dev/null | \
        grep -v "^>" | tr -d '\n' | tr '[:lower:]' '[:upper:]' > "${WORK_DIR}/seq_${var_id}.txt"
    
    local full_seq=$(cat "${WORK_DIR}/seq_${var_id}.txt")
    [[ -z "$full_seq" ]] && return 1
    
    local snp_pos_in_seq=$((pos - extract_start))
    
    # Create sequences with REF and ALT alleles
    local seq_ref="${full_seq:0:$snp_pos_in_seq}${ref}${full_seq:$((snp_pos_in_seq + 1))}"
    local seq_alt="${full_seq:0:$snp_pos_in_seq}${alt}${full_seq:$((snp_pos_in_seq + 1))}"
    
    # Design primers using Primer3
    # Forward REF primer
    cat > "${WORK_DIR}/p3_fwd_ref_${var_id}.txt" <<EOF
SEQUENCE_ID=fwd_ref
SEQUENCE_TEMPLATE=${seq_ref}
SEQUENCE_FORCE_LEFT_END=${snp_pos_in_seq}
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=1
PRIMER_PICK_RIGHT_PRIMER=0
PRIMER_OPT_SIZE=${PRIMER_OPT_SIZE}
PRIMER_MIN_SIZE=${PRIMER_MIN_SIZE}
PRIMER_MAX_SIZE=${PRIMER_MAX_SIZE}
PRIMER_OPT_TM=${PRIMER_OPT_TM}
PRIMER_MIN_TM=${PRIMER_MIN_TM}
PRIMER_MAX_TM=${PRIMER_MAX_TM}
PRIMER_MIN_GC=${PRIMER_MIN_GC}
PRIMER_MAX_GC=${PRIMER_MAX_GC}
PRIMER_NUM_RETURN=1
=
EOF
    
    # Forward ALT primer
    cat > "${WORK_DIR}/p3_fwd_alt_${var_id}.txt" <<EOF
SEQUENCE_ID=fwd_alt
SEQUENCE_TEMPLATE=${seq_alt}
SEQUENCE_FORCE_LEFT_END=${snp_pos_in_seq}
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=1
PRIMER_PICK_RIGHT_PRIMER=0
PRIMER_OPT_SIZE=${PRIMER_OPT_SIZE}
PRIMER_MIN_SIZE=${PRIMER_MIN_SIZE}
PRIMER_MAX_SIZE=${PRIMER_MAX_SIZE}
PRIMER_OPT_TM=${PRIMER_OPT_TM}
PRIMER_MIN_TM=${PRIMER_MIN_TM}
PRIMER_MAX_TM=${PRIMER_MAX_TM}
PRIMER_MIN_GC=${PRIMER_MIN_GC}
PRIMER_MAX_GC=${PRIMER_MAX_GC}
PRIMER_NUM_RETURN=1
=
EOF
    
    # Reverse common primer
    cat > "${WORK_DIR}/p3_rev_${var_id}.txt" <<EOF
SEQUENCE_ID=rev
SEQUENCE_TEMPLATE=${full_seq}
SEQUENCE_EXCLUDED_REGION=${snp_pos_in_seq},1
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=0
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=${PRIMER_OPT_SIZE}
PRIMER_MIN_SIZE=${PRIMER_MIN_SIZE}
PRIMER_MAX_SIZE=${PRIMER_MAX_SIZE}
PRIMER_OPT_TM=${PRIMER_OPT_TM}
PRIMER_MIN_TM=${PRIMER_MIN_TM}
PRIMER_MAX_TM=${PRIMER_MAX_TM}
PRIMER_MIN_GC=${PRIMER_MIN_GC}
PRIMER_MAX_GC=${PRIMER_MAX_GC}
PRIMER_NUM_RETURN=${PRIMER_NUM_RETURN}
=
EOF
    
    # Run Primer3
    primer3_core "${WORK_DIR}/p3_fwd_ref_${var_id}.txt" > "${WORK_DIR}/p3_fwd_ref_${var_id}_out.txt" 2>/dev/null
    primer3_core "${WORK_DIR}/p3_fwd_alt_${var_id}.txt" > "${WORK_DIR}/p3_fwd_alt_${var_id}_out.txt" 2>/dev/null
    primer3_core "${WORK_DIR}/p3_rev_${var_id}.txt" > "${WORK_DIR}/p3_rev_${var_id}_out.txt" 2>/dev/null
    
    # Check if all primers were designed
    local num_fwd_ref=$(grep "PRIMER_LEFT_NUM_RETURNED=" "${WORK_DIR}/p3_fwd_ref_${var_id}_out.txt" | cut -d'=' -f2)
    local num_fwd_alt=$(grep "PRIMER_LEFT_NUM_RETURNED=" "${WORK_DIR}/p3_fwd_alt_${var_id}_out.txt" | cut -d'=' -f2)
    local num_rev=$(grep "PRIMER_RIGHT_NUM_RETURNED=" "${WORK_DIR}/p3_rev_${var_id}_out.txt" | cut -d'=' -f2)
    
    if [[ -z "$num_fwd_ref" ]] || [[ "$num_fwd_ref" -eq 0 ]] || \
       [[ -z "$num_fwd_alt" ]] || [[ "$num_fwd_alt" -eq 0 ]] || \
       [[ -z "$num_rev" ]] || [[ "$num_rev" -eq 0 ]]; then
        return 1
    fi
    
    # Extract primer info
    local fwd_ref_seq=$(grep "PRIMER_LEFT_0_SEQUENCE=" "${WORK_DIR}/p3_fwd_ref_${var_id}_out.txt" | cut -d'=' -f2)
    local fwd_ref_tm=$(grep "PRIMER_LEFT_0_TM=" "${WORK_DIR}/p3_fwd_ref_${var_id}_out.txt" | cut -d'=' -f2)
    local fwd_ref_gc=$(grep "PRIMER_LEFT_0_GC_PERCENT=" "${WORK_DIR}/p3_fwd_ref_${var_id}_out.txt" | cut -d'=' -f2)
    
    local fwd_alt_seq=$(grep "PRIMER_LEFT_0_SEQUENCE=" "${WORK_DIR}/p3_fwd_alt_${var_id}_out.txt" | cut -d'=' -f2)
    local fwd_alt_tm=$(grep "PRIMER_LEFT_0_TM=" "${WORK_DIR}/p3_fwd_alt_${var_id}_out.txt" | cut -d'=' -f2)
    local fwd_alt_gc=$(grep "PRIMER_LEFT_0_GC_PERCENT=" "${WORK_DIR}/p3_fwd_alt_${var_id}_out.txt" | cut -d'=' -f2)
    
    # Process each reverse primer option
    for idx in $(seq 0 $((num_rev - 1))); do
        local rev_seq=$(grep "PRIMER_RIGHT_${idx}_SEQUENCE=" "${WORK_DIR}/p3_rev_${var_id}_out.txt" | cut -d'=' -f2)
        local rev_pos=$(grep "PRIMER_RIGHT_${idx}=" "${WORK_DIR}/p3_rev_${var_id}_out.txt" | head -1 | cut -d'=' -f2 | cut -d',' -f1)
        local rev_len=$(grep "PRIMER_RIGHT_${idx}=" "${WORK_DIR}/p3_rev_${var_id}_out.txt" | head -1 | cut -d'=' -f2 | cut -d',' -f2)
        local rev_tm=$(grep "PRIMER_RIGHT_${idx}_TM=" "${WORK_DIR}/p3_rev_${var_id}_out.txt" | cut -d'=' -f2)
        local rev_gc=$(grep "PRIMER_RIGHT_${idx}_GC_PERCENT=" "${WORK_DIR}/p3_rev_${var_id}_out.txt" | cut -d'=' -f2)
        
        # Add tails if requested
        local fwd_ref_final="$fwd_ref_seq"
        local fwd_alt_final="$fwd_alt_seq"
        if [[ "$USE_TAILS" == "true" ]]; then
            fwd_ref_final="${TAIL_FAM}${fwd_ref_seq}"
            fwd_alt_final="${TAIL_HEX}${fwd_alt_seq}"
        fi
        
        # Calculate coordinates
        local fwd_start=$extract_start
        local fwd_end=$((fwd_start + ${#fwd_ref_final} - 1))
        local rev_start=$((extract_start + rev_pos))
        local rev_end=$((rev_start + rev_len - 1))
        local amplicon_size=$((rev_end - fwd_start + 1))
        
        # Write output
        local marker_name="kasp_${chr}_${pos}_${idx}"
        echo -e "${marker_name}\t${chr}\t${pos}\t${fwd_start}\t${fwd_end}\tForward_REF_allele\t${fwd_ref_final}\t${#fwd_ref_final}\t${fwd_ref_tm}\t${fwd_ref_gc}\t${amplicon_size}\tfalse" >> "$OUTPUT_FILE"
        echo -e "${marker_name}\t${chr}\t${pos}\t${fwd_start}\t${fwd_end}\tForward_ALT_allele\t${fwd_alt_final}\t${#fwd_alt_final}\t${fwd_alt_tm}\t${fwd_alt_gc}\t${amplicon_size}\tfalse" >> "$OUTPUT_FILE"
        echo -e "${marker_name}\t${chr}\t${pos}\t${rev_start}\t${rev_end}\tReverse_common\t${rev_seq}\t${rev_len}\t${rev_tm}\t${rev_gc}\t${amplicon_size}\tfalse" >> "$OUTPUT_FILE"
    done
    
    return 0
}

# MODE 1: VCF + Region
if [[ "$MODE" == "VCF_REGION" ]]; then
    print_info "Processing VCF region: ${CHROM}:${START_POS}-${END_POS}"
    
    grep -v "^#" "$VCF_FILE" | awk -v chr="$CHROM" -v start="$START_POS" -v end="$END_POS" \
        '$1==chr && $2>=start && $2<=end' > "${WORK_DIR}/variants.txt"
    
    TOTAL_VARIANTS=$(wc -l < "${WORK_DIR}/variants.txt")
    print_info "Found ${TOTAL_VARIANTS} total variants in region"
    
    # Filter for SNPs only
    awk -F'\t' '{
        if (length($4) == 1 && length($5) == 1) {
            print $0
        }
    }' "${WORK_DIR}/variants.txt" > "${WORK_DIR}/snps.txt"
    
    SNP_COUNT=$(wc -l < "${WORK_DIR}/snps.txt")
    print_info "Found ${SNP_COUNT} SNPs"
    
    if [[ $SNP_COUNT -eq 0 ]]; then
        print_warn "No SNPs found"
        exit 0
    fi
    
    print_info "Designing KASP markers for ${SNP_COUNT} SNPs..."
    PROCESSED=0
    
    while IFS=$'\t' read -r chr pos id ref alt rest; do
        alt=$(echo "$alt" | cut -d',' -f1)
        var_id="${id:-${chr}_${pos}}"
        
        if design_kasp "$chr" "$pos" "$ref" "$alt" "$var_id"; then
            ((PROCESSED++))
            print_info "  Processed ${chr}:${pos} [${PROCESSED}/${SNP_COUNT}]"
        else
            print_warn "  Failed to design primers for ${chr}:${pos}"
        fi
    done < "${WORK_DIR}/snps.txt"
fi

# MODE 2: Position file
if [[ "$MODE" == "REGION_FILE" ]]; then
    print_info "Processing position file: ${REGION_FILE}"
    
    sed 's/\r$//' "$REGION_FILE" > "${WORK_DIR}/positions_clean.txt"
    
    PROCESSED=0
    TOTAL=$(grep -v "^#" "${WORK_DIR}/positions_clean.txt" | wc -l)
    
    print_info "Designing KASP markers for ${TOTAL} SNPs..."
    
    while IFS=$'\t' read -r chr pos ref alt rest; do
        [[ "$chr" =~ ^# ]] && continue
        [[ -z "$chr" ]] && continue
        
        if [[ -z "$ref" ]] || [[ -z "$alt" ]]; then
            print_warn "Skipping ${chr}:${pos} - REF and ALT required"
            continue
        fi
        
        var_id="${chr}_${pos}"
        
        if design_kasp "$chr" "$pos" "$ref" "$alt" "$var_id"; then
            ((PROCESSED++))
            print_info "  Processed ${chr}:${pos} [${PROCESSED}/${TOTAL}]"
        else
            print_warn "  Failed to design primers for ${chr}:${pos}"
        fi
    done < "${WORK_DIR}/positions_clean.txt"
fi

# Summary
TOTAL_MARKERS=$(grep -v "^Primer_name" "$OUTPUT_FILE" | wc -l)
print_info "Complete! Output: ${OUTPUT_FILE}"
print_info "Detailed results: ${WORK_DIR}/"
print_info "Total primers: ${TOTAL_MARKERS}"
