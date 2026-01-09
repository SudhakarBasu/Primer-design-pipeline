# Primer Design Pipeline - Examples

This directory contains example scripts and use cases for the primer design pipeline focused on large INDEL primer design.

## Quick Examples

### 1. Basic VCF Mode (INDEL Filtering)

Filter VCF for large INDELs (>10bp) and design primers:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -o example1_indels
```

**What happens:**
1. Filters VCF for INDELs >10bp
2. Generates `example1_indels_positions.txt` with filtered INDELs
3. Designs generic primers around each INDEL position

**Output**: 
- `example1_indels.txt` - Primer results
- `example1_indels_positions.txt` - Filtered INDEL positions
- `example1_indels_results/` - Intermediate files

---

### 2. Custom INDEL Size Threshold

Filter for larger INDELs (>20bp):

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --min-indel-size 20 \
  -o example2_large_indels
```

---

### 3. Large INDELs with Adjusted Parameters

For very large INDELs (e.g., 50-100bp), increase flanking length and product size:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -l 400 \
  --product-size-max 600 \
  --min-indel-size 50 \
  -o example3_very_large_indels
```

**Why adjust these parameters?**
- `-l 400`: Provides 400bp flanking sequence on each side
- `--product-size-max 600`: Allows larger amplicons to accommodate the INDEL
- `--min-indel-size 50`: Only processes INDELs ≥50bp

---

### 4. Position File Mode

Design primers from a pre-generated or custom position file:

```bash
bash generic_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f examples/example_regions.txt \
  -o example4_positions
```

**Position file format** (`example_regions.txt`):
```
# Positions only
1	662351
1	762351

# Or with variant info (for reference)
1	862351	ATCGATCGATCG	A	11
1	962351	GTGTGTGTGT	G	9
```

**Note:** The `ref`, `alt`, and `indel_size` columns are optional and used only for documentation. The script designs generic primers around the position.

---

### 5. Skip isPCR Validation (Faster)

For quick testing without off-target validation:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --no-ispcr \
  -o example5_fast
```

---

### 6. Custom Primer Parameters

Design primers with higher Tm and specific GC content:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --primer-tm-opt 62.0 \
  --primer-tm-min 60.0 \
  --primer-tm-max 65.0 \
  --primer-gc-min 45.0 \
  --primer-gc-max 55.0 \
  -o example6_custom_tm
```

---

### 7. Return More Primer Pairs

Get up to 5 primer pairs per position:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --num-return 5 \
  -o example7_more_primers
```

---

# KASP Primer Examples (`kasp_primers.sh`)

Examples for designing KASP (Kompetitive Allele-Specific PCR) primers with VCF quality filtering.

## Quick Examples

### 1. Basic KASP Markers from VCF

Design KASP markers with default quality filtering:

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  -o kasp_basic
```

**Output:** 3 primers per SNP
- Forward_REF_allele
- Forward_ALT_allele
- Reverse_common

**File:** `kasp_basic_kasp.txt`

---

### 2. High-Quality SNPs Only

Filter for high-quality SNPs (QUAL≥30, DP≥10):

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --min-qual 30 \
  --min-depth 10 \
  -o kasp_high_quality
```

---

### 3. With Fluorophore Tails

Add FAM/HEX tails for real-time detection:

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --use-tails \
  -o kasp_with_tails
```

**Primer format:**
- Forward_REF: `[FAM_TAIL][primer_sequence]`
- Forward_ALT: `[HEX_TAIL][primer_sequence]`

---

### 4. SNP at Penultimate Position

For better stability, position SNP at 2nd from 3' end:

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --snp-offset 1 \
  -o kasp_penultimate
```

**SNP position:**
- Offset 0 (default): `...ACGTACG[T]` (terminal)
- Offset 1: `...ACGTAC[T]G` (penultimate)

---

### 5. From Position File

Design KASP markers from a position file (4 columns required):

```bash
bash kasp_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f kasp_positions.txt \
  -o kasp_from_file
```

**Position file format** (`kasp_positions.txt`):
```
chr	pos	ref	alt
1	12345	A	G
1	67890	C	T
1	98765	G	A
```

---

### 6. Allow Multi-Allelic Variants

Include multi-allelic SNPs (takes first ALT):

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --allow-multiallelic \
  -o kasp_multiallelic
```

---

### 7. Custom Primer Parameters

Design KASP markers with custom Tm and product size:

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --primer-tm-opt 62.0 \
  --primer-tm-min 60.0 \
  --product-size-max 100 \
  -o kasp_custom
```

---

### 8. Complete KASP Pipeline

Full-featured KASP marker design:

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --min-qual 25 \
  --min-depth 8 \
  --use-tails \
  --snp-offset 1 \
  --primer-tm-opt 62.0 \
  --num-return 5 \
  -o kasp_complete
```

---

## KASP Output Structure

After running KASP examples, you'll get:

```
kasp_basic_kasp.txt             ← Main KASP marker results
kasp_basic_kasp_results/        ← Detailed intermediate files
  ├── variants.txt             (All variants from region)
  ├── filtered_snps.txt        (SNPs passing quality filters, sorted)
  ├── seq.fa                   (Extracted sequences)
  ├── p3_input.txt             (Primer3 input)
  ├── p3_output.txt            (Primer3 output)
```

## KASP Output File Columns

| Column | Example Value | Meaning |
|--------|--------------|---------|
| Marker_name | kasp_1_12345_0 | Unique ID |
| Chr | 1 | Chromosome |
| Position | 12345 | SNP position |
| REF | A | Reference allele |
| ALT | G | Alternate allele |
| Primer_type | Forward_REF_allele | Primer type |
| Sequence | GAAGGTGACCAAGTTCATGCT... | Full primer (with tail if used) |
| Length | 42 | Primer length (bp) |
| Tm | 60.5 | Melting temperature |
| GC_Percent | 55.0 | GC content |

## VCF Filtering Output Example

```
[INFO] Processing VCF region: 1:1-50000000
[INFO] Filtering: QUAL≥20, DP≥5, SNPs only
[INFO] Found 250 total variants in region
[INFO] Filtered results:
[INFO]   - Total variants: 250
[INFO]   - SNPs passing filters: 78
[INFO]   - Quality range: 20.5 - 99.8 (sorted highest first)
[INFO] Designing KASP markers for 78 SNPs...
[INFO]   Processed rs12345 (QUAL=99.8) [1/78]
[INFO]   Processed rs67890 (QUAL=95.3) [2/78]
...
```

## Quality Filtering Guidelines

| Threshold | Min QUAL | Min DP | Use Case |
|-----------|----------|--------|----------|
| Permissive | 10 | 3 | Exploratory, low coverage |
| Default | 20 | 5 | General use |
| Stringent | 30 | 10 | High confidence markers |
| Very Stringent | 50 | 20 | Critical applications |

---

## Expected Output Structure

After running any example, you'll get:

```
example1_indels.txt              ← Main primer results
example1_indels_positions.txt    ← Filtered INDEL positions (VCF mode only)
example1_indels_results/         ← Detailed intermediate files
  ├── variants.txt
  ├── seq.fa
  ├── p3_input.txt
  ├── p3_output.txt
  ├── ispcr_input.txt
  └── ispcr_output.txt
```

## Interpreting Results

### Position File Columns (VCF mode output)

| Column | Example Value | Meaning |
|--------|--------------|---------|
| chr | 1 | Chromosome |
| pos | 41169 | INDEL position |
| ref | ATCGATCGATCG | Reference allele |
| alt | A | Alternate allele |
| indel_size | 11 | Size of INDEL (bp) |

### Main Output File Columns

| Column | Example Value | Meaning |
|--------|--------------|---------|
| Primer_name | primer_1_41169_0 | Unique ID for primer pair |
| Chr | 1 | Chromosome |
| Position | 41169 | Target position |
| Start | 40919 | isPCR amplification start |
| End | 41419 | isPCR amplification end |
| Type | Forward Primer | Primer direction |
| Sequence | ACGTACGTACGT... | Primer sequence |
| Length | 20 | Primer length (bp) |
| Tm | 60.5 | Melting temperature (°C) |
| GC_Percent | 55.0 | GC content (%) |
| Amplicon_Size | 250 | PCR product size (bp) |
| Off_Target | false | Specificity check |

### Off-Target Interpretation

- **false**: Primer pair amplifies only the target site (good!)
- **true**: Primer pair may amplify multiple sites (review needed)

## Parameter Guidelines for Different INDEL Sizes

| INDEL Size | Flanking Length (`-l`) | Product Size Max | Example |
|------------|----------------------|------------------|---------|
| 10-30bp | 250 (default) | 300 (default) | Default settings |
| 30-50bp | 300 | 400 | `-l 300 --product-size-max 400` |
| 50-70bp | 350 | 500 | `-l 350 --product-size-max 500` |
| 70-100bp | 400+ | 600+ | `-l 400 --product-size-max 600` |

## Batch Processing

Process multiple regions in a loop:

```bash
# Create a list of regions
cat > batch_regions.txt <<EOF
1	40000	50000
1	100000	110000
1	200000	210000
EOF

# Process each region
while IFS=$'\t' read chr start end; do
    bash generic_primers.sh \
        -v test.vcf \
        -r Oryza_sativa.chr1.fa \
        -c $chr \
        -s $start \
        -e $end \
        -o primers_${chr}_${start}_${end}
done < batch_regions.txt
```

## Combining Results

Merge multiple output files:

```bash
# Combine all primer results (keep header from first file)
head -1 example1_indels.txt > combined_primers.txt
tail -n +2 -q example*.txt >> combined_primers.txt

# Combine all position files
head -1 example1_indels_positions.txt > combined_positions.txt
tail -n +2 -q example*_positions.txt >> combined_positions.txt
```

## Workflow Example: Complete Analysis

```bash
# Step 1: Filter VCF for large INDELs
bash generic_primers.sh \
  -v my_variants.vcf \
  -r reference.fa \
  -c chr1 \
  -s 1 \
  -e 50000000 \
  --min-indel-size 15 \
  -l 300 \
  --product-size-max 500 \
  -o indel_primers

# Step 2: Review the filtered positions
cat indel_primers_positions.txt

# Step 3: Check primer results
head -20 indel_primers.txt

# Step 4: Filter for primers without off-targets
awk -F'\t' '$12=="false"' indel_primers.txt > specific_primers.txt

# Step 5: Count successful designs
echo "Total positions: $(tail -n +2 indel_primers_positions.txt | wc -l)"
echo "Primer pairs designed: $(grep "Forward Primer" indel_primers.txt | wc -l)"
echo "Specific primers: $(grep "Forward Primer" specific_primers.txt | wc -l)"
```

## Troubleshooting Examples

### No primers designed for some positions

```bash
# Try increasing flanking length and relaxing Primer3 parameters
bash generic_primers.sh \
  -v test.vcf \
  -r reference.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -l 400 \
  --primer-size-min 18 \
  --primer-size-max 27 \
  --primer-tm-min 55.0 \
  --primer-tm-max 65.0 \
  --primer-gc-min 35.0 \
  --primer-gc-max 65.0 \
  -o relaxed_primers
```

### All primers have off-targets

```bash
# Check if genome has repetitive regions
# Try designing primers with stricter parameters
bash generic_primers.sh \
  -v test.vcf \
  -r reference.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --primer-size-min 22 \
  --primer-size-max 25 \
  --primer-tm-min 60.0 \
  --primer-gc-min 45.0 \
  --primer-gc-max 55.0 \
  -o strict_primers
```

## Next Steps

1. Review the position file to see which INDELs were selected
2. Check the primer output file
3. Filter for primers without off-targets
4. Select best primer pairs based on:
   - Tm values (closer to optimal)
   - GC content (balanced)
   - Off-target status (false preferred)
   - Product size (as needed)
5. Order primers for validation

For more details, see the main [README.md](../README.md).
