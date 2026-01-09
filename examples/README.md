# Examples Directory

This directory contains example commands and test data for the primer design pipeline.

## Files

- **EXAMPLE_COMMANDS.md** - Ready-to-run commands for both scripts
- **README.md** - This file

## Test Data (in parent directory)

- `test.vcf` - VCF file with test variants
- `position.txt` - Position file for direct primer design  
- `Oryza_sativa.chr1.fa` - Reference genome (rice chromosome 1)

## Quick Start

### 1. Generic Primers (INDEL Design)

```bash
# Basic INDEL filtering
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  -o example_indels
```

### 2. KASP Primers (SNP Genotyping)

```bash
# Basic KASP markers
bash kasp_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 1 \
  -e 50000000 \
  -o example_kasp
```

## More Examples

See [EXAMPLE_COMMANDS.md](EXAMPLE_COMMANDS.md) for comprehensive examples including:
- INDEL filtering with custom parameters
- Quality filtering for SNPs
- Fluorophore tails for KASP
- Position file usage
- Custom Primer3 parameters

## Expected Outputs

### Generic Primers
- `{prefix}.txt` - Primer results
- `{prefix}_positions.txt` - Filtered INDEL positions
- `{prefix}_results/` - Intermediate files

### KASP Primers
- `{prefix}_kasp.txt` - KASP marker results (3 primers per SNP)
- `{prefix}_kasp_results/` - Intermediate files including filtered SNPs

## Cleanup

Remove all example outputs:
```bash
rm -f example_*.txt
rm -rf example_*_results/
rm -rf example_*_kasp_results/
```
