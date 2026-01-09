#!/bin/bash
#
# KASP Primer Design Pipeline
# 
# Designs allele-specific primers for KASP genotyping
# Generates: 2 forward primers (allele-specific) + 1 common reverse primer

# Note: set -e removed to allow processing all positions even if some fail
set -u

# Parameters
VCF_FILE=""
REF_FASTA=""
CHROM=""
START_POS=""
END_POS=""
REGION_FILE=""
OUTPUT_PREFIX=""
FLANK_LENGTH=250

# VCF filtering parameters
MIN_QUAL=20          # Minimum variant quality score
MIN_DEPTH=5          # Minimum read depth
BIALLELIC_ONLY=true  # Filter only biallelic SNPs

# KASP-specific parameters
TAIL_FAM="GAAGGTGACCAAGTTCATGCT"  # FAM tail (default)
TAIL_HEX="GAAGGTCGGAGTCAACGGATT"  # HEX tail (default)
USE_TAILS=false
SNP_OFFSET=0  # Position of SNP from 3' end (0=terminal, 1=penultimate, etc.)

# Primer3 parameters for KASP
PRIMER_OPT_SIZE=20
PRIMER_MIN_SIZE=18
PRIMER_MAX_SIZE=25
PRIMER_OPT_TM=60.0
PRIMER_MIN_TM=57.0
PRIMER_MAX_TM=63.0
PRIMER_MIN_GC=40.0
PRIMER_MAX_GC=60.0
PRIMER_PRODUCT_MIN=50
PRIMER_PRODUCT_MAX=120
PRIMER_NUM_RETURN=3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

MODE 1: VCF + Region (SNP filtering with quality sorting)
  -v FILE     VCF file (filters for SNPs, sorted by quality)
  -r FILE     Reference genome FASTA
  -c CHR      Chromosome
  -s INT      Start position
  -e INT      End position
  -o PREFIX   Output prefix

MODE 2: Position file (4 columns required)
  -r FILE     Reference genome FASTA
  -f FILE     Position file (chr pos ref alt)
  -o PREFIX   Output prefix

VCF Filtering Options:
  --min-qual FLOAT        Minimum variant quality score [default: 20]
  --min-depth INT         Minimum read depth (DP) [default: 5]
  --allow-multiallelic    Allow multi-allelic variants [default: biallelic only]

KASP-Specific Options:
  -l INT              Flanking length [default: 250]
  --use-tails         Add 5' fluorophore tails to forward primers
  --tail-fam STR      FAM tail sequence [default: GAAGGTGACCAAGTTCATGCT]
  --tail-hex STR      HEX tail sequence [default: GAAGGTCGGAGTCAACGGATT]
  --snp-offset INT    SNP position from 3' end (0=terminal, 1=2nd from end, etc.) [default: 0]

Primer3 Parameters:
  --primer-size-min INT       [default: 18]
  --primer-size-opt INT       [default: 20]
  --primer-size-max INT       [default: 25]
  --primer-tm-min FLOAT       [default: 57.0]
  --primer-tm-opt FLOAT       [default: 60.0]
  --primer-tm-max FLOAT       [default: 63.0]
  --primer-gc-min FLOAT       [default: 40.0]
  --primer-gc-max FLOAT       [default: 60.0]
  --product-size-min INT      [default: 50]
  --product-size-max INT      [default: 120]
  --num-return INT            [default: 3]

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v) VCF_FILE="$2"; shift 2 ;;
        -r) REF_FASTA="$2"; shift 2 ;;
        -c) CHROM="$2"; shift 2 ;;
        -s) START_POS="$2"; shift 2 ;;
        -e) END_POS="$2"; shift 2 ;;
        -f) REGION_FILE="$2"; shift 2 ;;
        -o) OUTPUT_PREFIX="$2"; shift 2 ;;
        -l) FLANK_LENGTH="$2"; shift 2 ;;
        --use-tails) USE_TAILS=true; shift ;;
        --tail-fam) TAIL_FAM="$2"; shift 2 ;;
        --tail-hex) TAIL_HEX="$2"; shift 2 ;;
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
        --product-size-min) PRIMER_PRODUCT_MIN="$2"; shift 2 ;;
        --product-size-max) PRIMER_PRODUCT_MAX="$2"; shift 2 ;;
        --num-return) PRIMER_NUM_RETURN="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Validate
[[ -z "$REF_FASTA" ]] || [[ -z "$OUTPUT_PREFIX" ]] && print_error "Missing required arguments" && usage

# Determine mode
if [[ -n "$VCF_FILE" ]]; then
    [[ -z "$CHROM" ]] || [[ -z "$START_POS" ]] || [[ -z "$END_POS" ]] && print_error "VCF mode requires -c, -s, -e" && usage
    MODE="VCF_REGION"
elif [[ -n "$REGION_FILE" ]]; then
    MODE="REGION_FILE"
else
    print_error "Must specify either (-v -c -s -e) OR (-f)" && usage
fi

# Check files
[[ ! -f "$REF_FASTA" ]] && print_error "Reference not found: $REF_FASTA" && exit 1
[[ -n "$VCF_FILE" ]] && [[ ! -f "$VCF_FILE" ]] && print_error "VCF not found: $VCF_FILE" && exit 1
[[ -n "$REGION_FILE" ]] && [[ ! -f "$REGION_FILE" ]] && print_error "Region file not found: $REGION_FILE" && exit 1

# Check dependencies
for cmd in samtools primer3_core; do
    ! command -v $cmd &> /dev/null && print_error "Required: $cmd" && exit 1
done

# Create work directory
WORK_DIR="${OUTPUT_PREFIX}_results"
mkdir -p "$WORK_DIR"

# Index FASTA
if [[ ! -f "${REF_FASTA}.fai" ]]; then
    print_info "Indexing FASTA..."
    samtools faidx "$REF_FASTA"
fi

# Function to extract KASP sequence with bracket notation
# Replicates Python kasp_extractor.py logic in pure bash
extract_kasp_sequence() {
    local chr=$1
    local pos=$2
    local ref=$3
    local alt=$4
    local flank_len=$5
    
    # Calculate extraction region
    local extract_start=$((pos - flank_len))
    local extract_end=$((pos + ${#ref} + flank_len - 1))
    [[ $extract_start -lt 1 ]] && extract_start=1
    
    # Extract sequence from reference
    local region="${chr}:${extract_start}-${extract_end}"
    local full_seq=$(samtools faidx "$REF_FASTA" "$region" 2>/dev/null | grep -v "^>" | tr -d '\n' | tr '[:lower:]' '[:upper:]')
    
    if [[ -z "$full_seq" ]]; then
        echo "ERROR"
        return 1
    fi
    
    # Calculate variant position in extracted sequence (0-based)
    local var_pos_in_seq=$((pos - extract_start))
    
    # Extract upstream and downstream sequences
    local upstream=${full_seq:0:$var_pos_in_seq}
    local downstream=${full_seq:$((var_pos_in_seq + ${#ref}))}
    
    # Verify reference allele matches
    local ref_in_genome=${full_seq:$var_pos_in_seq:${#ref}}
    if [[ "$ref_in_genome" != "$ref" ]]; then
        print_warn "  Reference mismatch at ${chr}:${pos} (VCF: $ref, Genome: $ref_in_genome)"
    fi
    
    # Return in format: upstream|downstream|ref|alt
    echo "${upstream}|${downstream}|${ref}|${alt}"
    return 0
}

# Initialize output file
OUTPUT_FILE="${OUTPUT_PREFIX}.txt"
echo -e "Marker_name\tChr\tPosition\tREF\tALT\tPrimer_type\tSequence\tLength\tTm\tGC_Percent" > "$OUTPUT_FILE"

# Function to design KASP primers for a SNP
design_kasp() {
    local chr=$1
    local pos=$2
    local ref=$3
    local alt=$4
    local var_id=$5
    
    # KASP only works for SNPs
    if [[ ${#ref} -ne 1 ]] || [[ ${#alt} -ne 1 ]]; then
        print_warn "  Skipping ${chr}:${pos} - KASP requires SNPs (single base variants)"
        return 1
    fi
    
    # Extract sequence
    local extract_start=$((pos - FLANK_LENGTH))
    local extract_end=$((pos + FLANK_LENGTH))
    [[ $extract_start -lt 1 ]] && extract_start=1
    
    local region="${chr}:${extract_start}-${extract_end}"
    samtools faidx "$REF_FASTA" "$region" > "${WORK_DIR}/seq.fa" 2>/dev/null
    
    if [[ ! -s "${WORK_DIR}/seq.fa" ]]; then
        print_warn "  Failed to extract sequence for ${region}"
        return 1
    fi
    
    local full_seq=$(grep -v "^>" "${WORK_DIR}/seq.fa" | tr -d '\n' | tr '[:lower:]' '[:upper:]')
    local snp_pos_in_seq=$((pos - extract_start))
    
    # Design common reverse primer
    # Use Primer3 to pick right primer with SNP as excluded region
    cat > "${WORK_DIR}/p3_input.txt" <<EOF
SEQUENCE_ID=${var_id}
SEQUENCE_TEMPLATE=${full_seq}
SEQUENCE_EXCLUDED_REGION=${snp_pos_in_seq},1
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=0
PRIMER_PICK_INTERNAL_OLIGO=0
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=${PRIMER_OPT_SIZE}
PRIMER_MIN_SIZE=${PRIMER_MIN_SIZE}
PRIMER_MAX_SIZE=${PRIMER_MAX_SIZE}
PRIMER_OPT_TM=${PRIMER_OPT_TM}
PRIMER_MIN_TM=${PRIMER_MIN_TM}
PRIMER_MAX_TM=${PRIMER_MAX_TM}
PRIMER_MIN_GC=${PRIMER_MIN_GC}
PRIMER_MAX_GC=${PRIMER_MAX_GC}
PRIMER_MAX_POLY_X=4
PRIMER_NUM_RETURN=${PRIMER_NUM_RETURN}
PRIMER_EXPLAIN_FLAG=1
=
EOF
    
    primer3_core "${WORK_DIR}/p3_input.txt" > "${WORK_DIR}/p3_output.txt" 2>/dev/null
    
    local num_primers=$(grep "PRIMER_RIGHT_NUM_RETURNED=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
    
    if [[ -z "$num_primers" ]] || [[ "$num_primers" -eq 0 ]]; then
        print_warn "  No reverse primers designed for ${chr}:${pos}"
        return 1
    fi
    
    # Process each reverse primer option
    for i in $(seq 0 $((num_primers - 1))); do
        local right_seq=$(grep "PRIMER_RIGHT_${i}_SEQUENCE=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local right_len=$(grep "PRIMER_RIGHT_${i}=" "${WORK_DIR}/p3_output.txt" | head -1 | cut -d'=' -f2 | cut -d',' -f2)
        local right_tm=$(grep "PRIMER_RIGHT_${i}_TM=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local right_gc=$(grep "PRIMER_RIGHT_${i}_GC_PERCENT=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        
        # Design allele-specific forward primers
        # SNP position controlled by SNP_OFFSET (0=terminal, 1=penultimate, etc.)
        
        # Get sequence around SNP for forward primer design
        local upstream_seq=${full_seq:0:$snp_pos_in_seq}
        local downstream_seq=${full_seq:$((snp_pos_in_seq + 1))}
        
        # Extract bases after SNP for offset
        local offset_bases=""
        if [[ $SNP_OFFSET -gt 0 ]] && [[ ${#downstream_seq} -ge $SNP_OFFSET ]]; then
            offset_bases=${downstream_seq:0:$SNP_OFFSET}
        fi
        
        # Forward primer for REF allele (ends with REF base)
        local fwd_ref_core=""
        local fwd_ref_len=0
        local fwd_ref_tm=0
        local fwd_ref_gc=0
        
        # Try different lengths to find optimal primer
        # Primer structure: [upstream][REF][offset_bases]
        for len in $(seq $PRIMER_MAX_SIZE -1 $PRIMER_MIN_SIZE); do
            local core_len=$((len - SNP_OFFSET))
            if [[ ${#upstream_seq} -ge $((core_len - 1)) ]] && [[ $core_len -ge $PRIMER_MIN_SIZE ]]; then
                local primer_start=$((${#upstream_seq} - core_len + 1))
                fwd_ref_core="${upstream_seq:$primer_start}${ref}${offset_bases}"
                fwd_ref_len=${#fwd_ref_core}
                
                # Calculate Tm (simple approximation)
                local gc_count=$(echo "$fwd_ref_core" | grep -o "[GC]" | wc -l)
                local at_count=$(echo "$fwd_ref_core" | grep -o "[AT]" | wc -l)
                fwd_ref_tm=$(echo "scale=2; 4*$gc_count + 2*$at_count" | bc)
                fwd_ref_gc=$(echo "scale=2; 100*$gc_count/$fwd_ref_len" | bc)
                
                # Check if Tm is in acceptable range
                if (( $(echo "$fwd_ref_tm >= $PRIMER_MIN_TM" | bc -l) )) && (( $(echo "$fwd_ref_tm <= $PRIMER_MAX_TM" | bc -l) )); then
                    break
                fi
            fi
        done
        
        # Forward primer for ALT allele (ends with ALT base)
        local fwd_alt_core=""
        local fwd_alt_len=0
        local fwd_alt_tm=0
        local fwd_alt_gc=0
        
        for len in $(seq $PRIMER_MAX_SIZE -1 $PRIMER_MIN_SIZE); do
            local core_len=$((len - SNP_OFFSET))
            if [[ ${#upstream_seq} -ge $((core_len - 1)) ]] && [[ $core_len -ge $PRIMER_MIN_SIZE ]]; then
                local primer_start=$((${#upstream_seq} - core_len + 1))
                fwd_alt_core="${upstream_seq:$primer_start}${alt}${offset_bases}"
                fwd_alt_len=${#fwd_alt_core}
                
                local gc_count=$(echo "$fwd_alt_core" | grep -o "[GC]" | wc -l)
                local at_count=$(echo "$fwd_alt_core" | grep -o "[AT]" | wc -l)
                fwd_alt_tm=$(echo "scale=2; 4*$gc_count + 2*$at_count" | bc)
                fwd_alt_gc=$(echo "scale=2; 100*$gc_count/$fwd_alt_len" | bc)
                
                if (( $(echo "$fwd_alt_tm >= $PRIMER_MIN_TM" | bc -l) )) && (( $(echo "$fwd_alt_tm <= $PRIMER_MAX_TM" | bc -l) )); then
                    break
                fi
            fi
        done
        
        # Add tails if requested
        local fwd_ref_final="$fwd_ref_core"
        local fwd_alt_final="$fwd_alt_core"
        
        if [[ "$USE_TAILS" == "true" ]]; then
            fwd_ref_final="${TAIL_FAM}${fwd_ref_core}"
            fwd_alt_final="${TAIL_HEX}${fwd_alt_core}"
        fi
        
        # Marker name
        local marker_name="kasp_${chr}_${pos}_${i}"
        
        # Write to output
        echo -e "${marker_name}\t${chr}\t${pos}\t${ref}\t${alt}\tForward_REF_allele\t${fwd_ref_final}\t${#fwd_ref_final}\t${fwd_ref_tm}\t${fwd_ref_gc}" >> "$OUTPUT_FILE"
        echo -e "${marker_name}\t${chr}\t${pos}\t${ref}\t${alt}\tForward_ALT_allele\t${fwd_alt_final}\t${#fwd_alt_final}\t${fwd_alt_tm}\t${fwd_alt_gc}" >> "$OUTPUT_FILE"
        echo -e "${marker_name}\t${chr}\t${pos}\t${ref}\t${alt}\tReverse_common\t${right_seq}\t${right_len}\t${right_tm}\t${right_gc}" >> "$OUTPUT_FILE"
    done
    
    return 0
}

# MODE 1: VCF + Region (with quality filtering and sorting)
if [[ "$MODE" == "VCF_REGION" ]]; then
    print_info "Processing VCF region: ${CHROM}:${START_POS}-${END_POS}"
    
    # Extract variants from region
    grep -v "^#" "$VCF_FILE" | awk -v chr="$CHROM" -v start="$START_POS" -v end="$END_POS" \
        '$1==chr && $2>=start && $2<=end' > "${WORK_DIR}/variants.txt"
    
    TOTAL_VARIANTS=$(wc -l < "${WORK_DIR}/variants.txt")
    print_info "Found ${TOTAL_VARIANTS} total variants in region"
    
    # Check if QUAL and DP fields are available in VCF
    if [[ $TOTAL_VARIANTS -gt 0 ]]; then
        FIRST_VARIANT=$(head -1 "${WORK_DIR}/variants.txt")
        QUAL_FIELD=$(echo "$FIRST_VARIANT" | cut -f6)
        INFO_FIELD=$(echo "$FIRST_VARIANT" | cut -f8)
        
        HAS_QUAL=false
        HAS_DP=false
        
        [[ "$QUAL_FIELD" != "." ]] && [[ "$QUAL_FIELD" =~ ^[0-9]+(\.[0-9]+)?$ ]] && HAS_QUAL=true
        [[ "$INFO_FIELD" =~ DP= ]] && HAS_DP=true
        
        # Update filtering message based on available fields
        if [[ "$HAS_QUAL" == "true" ]] && [[ "$HAS_DP" == "true" ]]; then
            print_info "Filtering: QUAL≥${MIN_QUAL}, DP≥${MIN_DEPTH}, SNPs only"
        elif [[ "$HAS_QUAL" == "true" ]]; then
            print_info "Filtering: QUAL≥${MIN_QUAL}, SNPs only (DP not available)"
        elif [[ "$HAS_DP" == "true" ]]; then
            print_info "Filtering: DP≥${MIN_DEPTH}, SNPs only (QUAL not available)"
        else
            print_info "Filtering: SNPs only (QUAL and DP not available - accepting all SNPs)"
        fi
    fi
    
    # Filter by quality, depth, and SNP type, then sort by quality (descending)
    # Smart filtering: if QUAL/DP not available, skip quality filters
    awk -F'\t' -v minq="$MIN_QUAL" -v mind="$MIN_DEPTH" -v biallelic="$BIALLELIC_ONLY" '
    {
        chr = $1
        pos = $2
        id = $3
        ref = $4
        alt = $5
        qual = $6
        info = $8
        
        # Check if QUAL field exists and is numeric
        has_qual = (qual != "." && qual ~ /^[0-9]+(\.[0-9]+)?$/)
        
        # Extract DP from INFO field
        dp = 0
        has_dp = 0
        if (match(info, /DP=([0-9]+)/, dp_arr)) {
            dp = dp_arr[1]
            has_dp = 1
        }
        
        # Filter for SNPs only (single base ref and alt)
        if (length(ref) == 1 && length(alt) == 1) {
            # Handle multi-allelic if needed
            if (biallelic == "true" && index(alt, ",") > 0) {
                next  # Skip multi-allelic
            }
            
            # Take first ALT if multi-allelic
            if (index(alt, ",") > 0) {
                split(alt, alts, ",")
                alt = alts[1]
            }
            
            # Apply quality and depth filters ONLY if fields exist
            # If fields missing, accept all SNPs
            if (has_qual && has_dp) {
                # Both QUAL and DP available - apply filters
                if (qual >= minq && dp >= mind) {
                    print $0 "\t" qual  # Append quality for sorting
                }
            } else if (has_qual && !has_dp) {
                # Only QUAL available - filter by QUAL only
                if (qual >= minq) {
                    print $0 "\t" qual
                }
            } else if (!has_qual && has_dp) {
                # Only DP available - filter by DP only
                if (dp >= mind) {
                    print $0 "\t0"  # Use 0 as placeholder quality
                }
            } else {
                # Neither QUAL nor DP available - accept all SNPs
                print $0 "\t0"  # Use 0 as placeholder quality
            }
        }
    }' "${WORK_DIR}/variants.txt" | \
    sort -t$'\t' -k11,11nr > "${WORK_DIR}/filtered_snps.txt"  # Sort by quality (column 11) descending
    
    SNP_COUNT=$(wc -l < "${WORK_DIR}/filtered_snps.txt")
    
    print_info "Filtered results:"
    print_info "  - Total variants: ${TOTAL_VARIANTS}"
    print_info "  - SNPs passing filters: ${SNP_COUNT}"
    
    if [[ $SNP_COUNT -eq 0 ]]; then
        print_warn "No SNPs passed quality filters (QUAL≥${MIN_QUAL}, DP≥${MIN_DEPTH})"
        print_info "Complete! No KASP markers designed."
        exit 0
    fi
    
    # Get quality range for logging
    QUAL_MAX=$(head -1 "${WORK_DIR}/filtered_snps.txt" | cut -f11)
    QUAL_MIN=$(tail -1 "${WORK_DIR}/filtered_snps.txt" | cut -f11)
    print_info "  - Quality range: ${QUAL_MIN} - ${QUAL_MAX} (sorted highest first)"
    
    print_info "Designing KASP markers for ${SNP_COUNT} SNPs..."
    PROCESSED=0
    
    while IFS=$'\t' read -r chr pos id ref alt qual filter info format sample rest_qual; do
        # Take first ALT allele
        alt=$(echo "$alt" | cut -d',' -f1)
        
        if design_kasp "$chr" "$pos" "$ref" "$alt" "$id"; then
            ((PROCESSED++))
            print_info "  Processed ${id} (QUAL=${rest_qual}) [${PROCESSED}/${SNP_COUNT}]"
        fi
    done < "${WORK_DIR}/filtered_snps.txt"
fi

# MODE 2: Region file
if [[ "$MODE" == "REGION_FILE" ]]; then
    print_info "Processing region file"
    
    # Convert Windows line endings
    sed -i 's/\r$//' "$REGION_FILE" 2>/dev/null || true
    
    REGION_COUNT=$(grep -v "^$" "$REGION_FILE" | grep -v "^#" | wc -l)
    PROCESSED=0
    
    while IFS=$'\t' read -r chr pos ref alt rest; do
        [[ -z "$chr" ]] && continue
        [[ "$chr" =~ ^# ]] && continue
        [[ -z "$pos" ]] && continue
        
        # KASP requires ref and alt alleles
        if [[ -z "$ref" ]] || [[ -z "$alt" ]]; then
            print_warn "Skipping ${chr}:${pos} - KASP requires REF and ALT alleles"
            continue
        fi
        
        print_info "Processing ${chr}:${pos} (${ref}>${alt})..."
        
        var_id="${chr}_${pos}"
        if design_kasp "$chr" "$pos" "$ref" "$alt" "$var_id"; then
            ((PROCESSED++))
            print_info "  Designed KASP markers (${PROCESSED}/${REGION_COUNT})"
        fi
    done < "$REGION_FILE"
fi

print_info "Complete! Output: ${OUTPUT_FILE}"
print_info "Detailed results: ${WORK_DIR}/"
print_info "Total markers: $(( $(wc -l < "$OUTPUT_FILE") - 1 ))"
