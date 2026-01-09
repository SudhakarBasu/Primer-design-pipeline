# Example Commands for Primer Design Pipeline

This file contains ready-to-run commands using the provided test data.

## Test Data Files
- `test.vcf` - VCF file with variants
- `position.txt` - Position file for direct primer design
- `Oryza_sativa.chr1.fa` - Reference genome (chromosome 1)

---

## Generic Primers (INDEL Design)

### Example 1: Basic INDEL Filtering
Filter VCF for large INDELs (>10bp) and design primers:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  -o example_indels
```

**Output:**
- `example_indels.txt` - Primer results
- `example_indels_positions.txt` - Filtered INDEL positions
- `example_indels_results/` - Intermediate files

---

### Example 2: Large INDELs with Custom Parameters
For very large INDELs (>50bp) with increased flanking:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  -l 300 \
  --product-size-max 500 \
  --min-indel-size 50 \
  -o example_large_indels
```

---

### Example 3: From Position File
Design primers from position file:

```bash
bash generic_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f position.txt \
  -o example_positions
```

---

### Example 4: Without isPCR Validation (Faster)
Skip off-target validation for quick testing:

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --no-ispcr \
  -o example_fast
```

---

## KASP Primers (SNP Genotyping)

### Example 5: Basic KASP Markers
Design KASP markers with default quality filtering:

```bash
bash kasp_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  -o example_kasp
```

**Output:**
- `example_kasp_kasp.txt` - 3 primers per SNP (Forward_REF, Forward_ALT, Reverse_common)
- `example_kasp_kasp_results/` - Intermediate files

---

### Example 6: High-Quality SNPs Only
Filter for high-quality SNPs (QUAL≥30, DP≥10):

```bash
bash kasp_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --min-qual 30 \
  --min-depth 10 \
  -o example_kasp_hq
```

---

### Example 7: KASP with Fluorophore Tails
Add FAM/HEX tails for real-time detection:

```bash
bash kasp_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  --use-tails \
  --snp-offset 1 \
  -o example_kasp_tails
```

---

### Example 8: KASP from Position File
Design KASP markers from position file (requires 4 columns: chr, pos, ref, alt):

**Note:** First create a KASP position file with 4 columns:
```bash
# Create kasp_positions.txt with format: chr pos ref alt
echo -e "1\t12345\tA\tG" > kasp_positions.txt
echo -e "1\t67890\tC\tT" >> kasp_positions.txt
```

Then run:
```bash
bash kasp_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f kasp_positions.txt \
  -o example_kasp_file
```

---

## Quick Test Commands

### Test Generic Primers (Small Region)
```bash
bash generic_primers.sh -v test.vcf -r Oryza_sativa.chr1.fa -c 1 -s 40000 -e 50000 -o test_generic
```

### Test KASP Primers (Small Region)
```bash
bash kasp_primers.sh -v test.vcf -r Oryza_sativa.chr1.fa -c 1 -s 40000 -e 50000 -o test_kasp
```

---

## Expected Output Files

### Generic Primers
```
example_indels.txt                  ← Main output
example_indels_positions.txt        ← Filtered INDELs
example_indels_results/
  ├── variants.txt
  ├── seq.fa
  ├── p3_input.txt
  ├── p3_output.txt
  ├── ispcr_input.txt
  └── ispcr_output.txt
```

### KASP Primers
```
example_kasp_kasp.txt              ← Main output
example_kasp_kasp_results/
  ├── variants.txt
  ├── filtered_snps.txt            ← Quality-filtered SNPs
  ├── seq.fa
  ├── p3_input.txt
  └── p3_output.txt
```

---

## Cleanup Commands

Remove all example outputs:
```bash
rm -f example_*.txt
rm -rf example_*_results/
rm -rf example_*_kasp_results/
```

Or on Windows:
```powershell
Remove-Item example_*.txt -Force
Remove-Item example_*_results -Recurse -Force
Remove-Item example_*_kasp_results -Recurse -Force
```
