# Primer Design Pipeline - Examples

This directory contains example scripts and use cases for the primer design pipeline.

## Quick Examples

### 1. Basic VCF Mode

Design primers for all variants in a specific region:

```bash
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -o example1_vcf
```

**Output**: `example1_vcf_final_output.txt`

---

### 2. Region File Mode (General Primers)

Design primers for specific positions without variant information:

```bash
bash design_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f examples/example_regions.txt \
  -o example2_general
```

**Output**: `example2_general_final_output.txt`

---

### 3. Custom Primer Parameters

Design primers with higher Tm and smaller product size:

```bash
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --primer-tm-opt 62.0 \
  --primer-tm-min 60.0 \
  --primer-tm-max 65.0 \
  --product-size-max 200 \
  -o example3_custom
```

---

### 4. Skip isPCR Validation (Faster)

For quick testing without off-target validation:

```bash
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --no-ispcr \
  -o example4_fast
```

---

### 5. Longer Flanking Sequences

Increase flanking length for better primer options:

```bash
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -l 300 \
  -o example5_long_flank
```

---

### 6. Return More Primer Pairs

Get up to 5 primer pairs per variant:

```bash
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --num-return 5 \
  -o example6_more_primers
```

---

## Expected Output Structure

After running any example, you'll get:

```
example1_vcf_final_output.txt    ← Main result file
example1_vcf_results/            ← Detailed intermediate files
  ├── variants.txt
  ├── seq.fa
  ├── p3_input.txt
  ├── p3_output.txt
  ├── ispcr_input.txt
  └── ispcr_output.txt
```

## Interpreting Results

### Main Output File Columns

| Column | Example Value | Meaning |
|--------|--------------|---------|
| Primer_name | indel_1_41169_0 | Unique ID for primer pair |
| Chr | 1 | Chromosome |
| Position | 41169 | Variant position |
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

## Batch Processing

Process multiple regions in a loop:

```bash
# Create a list of regions
cat > batch_regions.txt << EOF
1	40000	50000
1	100000	110000
1	200000	210000
EOF

# Process each region
while IFS=$'\t' read chr start end; do
    bash design_primers.sh \
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
# Combine all results (keep header from first file)
head -1 example1_vcf_final_output.txt > combined_primers.txt
tail -n +2 -q example*_final_output.txt >> combined_primers.txt
```

## Next Steps

1. Review the output file
2. Check off-target status
3. Select best primer pairs based on:
   - Tm values (closer to optimal)
   - GC content (balanced)
   - Off-target status (false preferred)
   - Product size (as needed)

For more details, see the main [README.md](../README.md).
