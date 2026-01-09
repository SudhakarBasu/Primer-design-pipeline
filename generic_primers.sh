#!/bin/bash
#
# Primer Design Pipeline - Single Output File Format
# 
# Generates: final_output.txt with all primers in tabular format

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
SKIP_ISPCR=false
MIN_INDEL_SIZE=10

# Primer3 parameters
PRIMER_OPT_SIZE=20
PRIMER_MIN_SIZE=18
PRIMER_MAX_SIZE=25
PRIMER_OPT_TM=60.0
PRIMER_MIN_TM=57.0
PRIMER_MAX_TM=63.0
PRIMER_MIN_GC=40.0
PRIMER_MAX_GC=60.0
PRIMER_PRODUCT_MIN=100
PRIMER_PRODUCT_MAX=300
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
    cat << EOF
Usage: $0 [OPTIONS]

MODE 1: VCF + Region (INDEL Filtering)
  -v FILE     VCF file (filters for INDELs > ${MIN_INDEL_SIZE}bp)
  -r FILE     Reference genome FASTA
  -c CHR      Chromosome
  -s INT      Start position
  -e INT      End position
  -o PREFIX   Output prefix
  
  This mode filters VCF for large INDELs, generates a position file,
  then designs generic primers around those positions.

MODE 2: Position file
  -r FILE     Reference genome FASTA
  -f FILE     Position file (chr pos [ref alt])
              Note: ref/alt columns are optional and used only for reference
  -o PREFIX   Output prefix

Optional:
  -l INT              Flanking length [default: 250]
  --min-indel-size INT  Minimum INDEL size for VCF filtering [default: 10]
  --no-ispcr          Skip isPCR validation

IMPORTANT: For large INDELs (e.g., 70bp deletions), increase flanking length
           and product size to ensure primers don't fall in deleted regions.
           Example: -l 300 --product-size-max 500

Primer3 Parameters:
  --primer-size-min INT       [default: 18]
  --primer-size-opt INT       [default: 20]
  --primer-size-max INT       [default: 25]
  --primer-tm-min FLOAT       [default: 57.0]
  --primer-tm-opt FLOAT       [default: 60.0]
  --primer-tm-max FLOAT       [default: 63.0]
  --primer-gc-min FLOAT       [default: 40.0]
  --primer-gc-max FLOAT       [default: 60.0]
  --product-size-min INT      [default: 100]
  --product-size-max INT      [default: 300]
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
        --no-ispcr) SKIP_ISPCR=true; shift ;;
        --min-indel-size) MIN_INDEL_SIZE="$2"; shift 2 ;;
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

if [[ "$SKIP_ISPCR" == "false" ]] && ! command -v isPcr &> /dev/null; then
    print_warn "isPcr not found - validation skipped"
    SKIP_ISPCR=true
fi

# Create work directory
WORK_DIR="${OUTPUT_PREFIX}_results"
mkdir -p "$WORK_DIR"
print_info "Work directory created: ${WORK_DIR}"

# Index FASTA
if [[ ! -f "${REF_FASTA}.fai" ]]; then
    print_info "Indexing FASTA..."
    samtools faidx "$REF_FASTA"
fi

# Initialize output file
OUTPUT_FILE="${OUTPUT_PREFIX}.txt"
echo -e "Primer_name\tChr\tPosition\tStart\tEnd\tType\tSequence\tLength\tTm\tGC_Percent\tAmplicon_Size\tOff_Target" > "$OUTPUT_FILE"

# Function to design primers around a position (no variant)
process_position() {
    local chr=$1
    local pos=$2
    local var_id=$3
    
    # Extract sequence around the position
    local extract_start=$((pos - FLANK_LENGTH))
    local extract_end=$((pos + FLANK_LENGTH))
    [[ $extract_start -lt 1 ]] && extract_start=1
    
    local region="${chr}:${extract_start}-${extract_end}"
    samtools faidx "$REF_FASTA" "$region" > "${WORK_DIR}/seq.fa" 2>/dev/null
    
    if [[ ! -s "${WORK_DIR}/seq.fa" ]]; then
        return 1
    fi
    
    local full_seq=$(grep -v "^>" "${WORK_DIR}/seq.fa" | tr -d '\n' | tr '[:lower:]' '[:upper:]')
    
    # Calculate target position in the extracted sequence (1bp at the center)
    local var_pos_in_seq=$((pos - extract_start))
    
    # Primer3 input - target is 1bp at the specified position
    cat > "${WORK_DIR}/p3_input.txt" <<EOF
SEQUENCE_ID=${var_id}
SEQUENCE_TEMPLATE=${full_seq}
SEQUENCE_TARGET=${var_pos_in_seq},1
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=1
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
PRIMER_PRODUCT_SIZE_RANGE=${PRIMER_PRODUCT_MIN}-${PRIMER_PRODUCT_MAX}
PRIMER_NUM_RETURN=${PRIMER_NUM_RETURN}
PRIMER_EXPLAIN_FLAG=1
=
EOF
    
    primer3_core "${WORK_DIR}/p3_input.txt" > "${WORK_DIR}/p3_output.txt" 2>/dev/null
    
    local num_primers=$(grep "PRIMER_PAIR_NUM_RETURNED=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
    
    if [[ -z "$num_primers" ]] || [[ "$num_primers" -eq 0 ]]; then
        return 1
    fi
    
    # Process each primer pair
    for i in $(seq 0 $((num_primers - 1))); do
        local left_seq=$(grep "PRIMER_LEFT_${i}_SEQUENCE=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local right_seq=$(grep "PRIMER_RIGHT_${i}_SEQUENCE=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local left_len=$(grep "PRIMER_LEFT_${i}=" "${WORK_DIR}/p3_output.txt" | head -1 | cut -d'=' -f2 | cut -d',' -f2)
        local right_len=$(grep "PRIMER_RIGHT_${i}=" "${WORK_DIR}/p3_output.txt" | head -1 | cut -d'=' -f2 | cut -d',' -f2)
        local left_tm=$(grep "PRIMER_LEFT_${i}_TM=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local right_tm=$(grep "PRIMER_RIGHT_${i}_TM=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local left_gc=$(grep "PRIMER_LEFT_${i}_GC_PERCENT=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local right_gc=$(grep "PRIMER_RIGHT_${i}_GC_PERCENT=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        local product_size=$(grep "PRIMER_PAIR_${i}_PRODUCT_SIZE=" "${WORK_DIR}/p3_output.txt" | cut -d'=' -f2)
        
        # isPCR validation
        local ispcr_start="$extract_start"
        local ispcr_end="$extract_end"
        local off_target="false"
        
        if [[ "$SKIP_ISPCR" == "false" ]]; then
            echo -e "${var_id}_${i}\t${left_seq}\t${right_seq}\t50\t500" > "${WORK_DIR}/ispcr_input.txt"
            
            isPcr "$REF_FASTA" "${WORK_DIR}/ispcr_input.txt" "${WORK_DIR}/ispcr_output.txt" \
                -minPerfect=15 -minGood=15 -tileSize=11 2>/dev/null || true
            
            if [[ -f "${WORK_DIR}/ispcr_output.txt" ]]; then
                local hit_count=$(grep -c "^>" "${WORK_DIR}/ispcr_output.txt" 2>/dev/null || echo "0")
                
                if [[ $hit_count -gt 1 ]]; then
                    off_target="true"
                fi
                
                # Get first hit coordinates
                local first_hit=$(grep "^>" "${WORK_DIR}/ispcr_output.txt" | head -1)
                if [[ -n "$first_hit" ]]; then
                    if [[ "$first_hit" =~ :([0-9]+)[+]([0-9]+) ]]; then
                        ispcr_start="${BASH_REMATCH[1]}"
                        ispcr_end="${BASH_REMATCH[2]}"
                    elif [[ "$first_hit" =~ :([0-9]+)[-]([0-9]+) ]]; then
                        ispcr_start="${BASH_REMATCH[1]}"
                        ispcr_end="${BASH_REMATCH[2]}"
                    fi
                fi
            fi
        fi
        
        # Primer name
        local primer_name="primer_${chr}_${pos}_${i}"
        
        # Write forward primer
        echo -e "${primer_name}\t${chr}\t${pos}\t${ispcr_start}\t${ispcr_end}\tForward Primer\t${left_seq}\t${left_len}\t${left_tm}\t${left_gc}\t${product_size}\t${off_target}" >> "$OUTPUT_FILE"
        
        # Write reverse primer
        echo -e "\t\t\t\t\tReverse Primer\t${right_seq}\t${right_len}\t${right_tm}\t${right_gc}\t\t" >> "$OUTPUT_FILE"
    done
    
    return 0
}


# MODE 1: VCF + Region (INDEL Filtering)
if [[ "$MODE" == "VCF_REGION" ]]; then
    print_info "Processing VCF region: ${CHROM}:${START_POS}-${END_POS}"
    print_info "Filtering for INDELs > ${MIN_INDEL_SIZE}bp"
    
    # Extract variants from region
    grep -v "^#" "$VCF_FILE" | awk -v chr="$CHROM" -v start="$START_POS" -v end="$END_POS" \
        '$1==chr && $2>=start && $2<=end' > "${WORK_DIR}/variants.txt"
    
    VARIANT_COUNT=$(wc -l < "${WORK_DIR}/variants.txt")
    print_info "Found ${VARIANT_COUNT} total variants in region"
    
    # Generate position file with INDEL filtering
    POSITION_FILE="${WORK_DIR}/positions.txt"
    echo -e "#chr\tpos\tref\talt\tindel_size" > "$POSITION_FILE"
    
    INDEL_COUNT=0
    SNP_COUNT=0
    SMALL_INDEL_COUNT=0
    
    while IFS=$'\t' read -r chr pos id ref alt rest; do
        # Take first ALT allele
        alt=$(echo "$alt" | cut -d',' -f1)
        
        # Skip very large variants (likely structural variants or errors)
        [[ ${#ref} -gt 1000 ]] || [[ ${#alt} -gt 1000 ]] && continue
        
        # Calculate INDEL size
        ref_len=${#ref}
        alt_len=${#alt}
        indel_size=$((ref_len > alt_len ? ref_len - alt_len : alt_len - ref_len))
        
        # Filter: Skip SNPs
        if [[ $ref_len -eq 1 ]] && [[ $alt_len -eq 1 ]]; then
            ((SNP_COUNT++))
            continue
        fi
        
        # Filter: Skip small INDELs
        if [[ $indel_size -le $MIN_INDEL_SIZE ]]; then
            ((SMALL_INDEL_COUNT++))
            continue
        fi
        
        # This is a large INDEL - add to position file
        echo -e "${chr}\t${pos}\t${ref}\t${alt}\t${indel_size}" >> "$POSITION_FILE"
        ((INDEL_COUNT++))
    done < "${WORK_DIR}/variants.txt"
    
    print_info "Filtered results:"
    print_info "  - SNPs skipped: ${SNP_COUNT}"
    print_info "  - Small INDELs (<=${MIN_INDEL_SIZE}bp) skipped: ${SMALL_INDEL_COUNT}"
    print_info "  - Large INDELs (>${MIN_INDEL_SIZE}bp) selected: ${INDEL_COUNT}"
    print_info "Generated position file: ${POSITION_FILE}"
    
    if [[ $INDEL_COUNT -eq 0 ]]; then
        print_warn "No INDELs >${MIN_INDEL_SIZE}bp found in region"
        print_info "Complete! No primers designed."
        exit 0
    fi
    
    # Now process the generated position file
    print_info "Designing generic primers for ${INDEL_COUNT} INDELs..."
    PROCESSED=0
    
    while IFS=$'\t' read -r chr pos ref alt indel_size; do
        # Skip header
        [[ "$chr" =~ ^# ]] && continue
        
        var_id="primer_${chr}_${pos}"
        if process_position "$chr" "$pos" "$var_id"; then
            ((PROCESSED++))
            print_info "  Processed ${chr}:${pos} (INDEL ${indel_size}bp) [${PROCESSED}/${INDEL_COUNT}]"
        else
            print_warn "  Could not design primers for ${chr}:${pos}"
        fi
    done < "$POSITION_FILE"
fi

# MODE 2: Position file
if [[ "$MODE" == "REGION_FILE" ]]; then
    print_info "Processing position file: ${REGION_FILE}"
    
    # Convert Windows line endings to Unix (handle CRLF)
    sed -i 's/\r$//' "$REGION_FILE" 2>/dev/null || true
    
    REGION_COUNT=$(grep -v "^$" "$REGION_FILE" | grep -v "^#" | wc -l)
    print_info "Found ${REGION_COUNT} positions"
    PROCESSED=0
    
    while IFS=$'\t' read -r chr pos ref alt rest; do
        # Skip empty lines and comments
        [[ -z "$chr" ]] && continue
        [[ "$chr" =~ ^# ]] && continue
        [[ -z "$pos" ]] && continue
        
        # Design generic primers using only chr and pos
        # ref and alt columns are ignored (used only for reference/documentation)
        var_id="primer_${chr}_${pos}"
        if process_position "$chr" "$pos" "$var_id"; then
            ((PROCESSED++))
            print_info "  Processed ${chr}:${pos} [${PROCESSED}/${REGION_COUNT}]"
        else
            print_warn "  Could not design primers for ${chr}:${pos}"
        fi
    done < "$REGION_FILE"
fi

print_info "Complete! Output: ${OUTPUT_FILE}"
print_info "Detailed results: ${WORK_DIR}/"
print_info "Total primers: $(( $(wc -l < "$OUTPUT_FILE") - 1 ))"
