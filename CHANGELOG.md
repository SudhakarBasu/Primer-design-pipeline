# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-01-10

### KASP Primers - Proper Primer3 Integration

#### Added
- Proper Primer3 KASP design using `PRIMER_TASK=pick_detection_primers`
- Automatic N-region detection (skips sequences with >100 Ns)
- KASP-specific Primer3 parameters:
  - `PRIMER_MAX_DIFF_TM=2.0`
  - `PRIMER_GC_CLAMP=1`
  - `PRIMER_PRODUCT_SIZE_RANGE=60-150`
- Output format now matches `generic_primers.sh` (Start, End, Amplicon_Size, Off_Target columns)

#### Changed
- Rewrote `design_kasp()` function to use proper Primer3 approach
- Simplified script from ~600 to ~400 lines
- Removed complex helper functions
- Improved error handling for early chromosome positions

#### Fixed
- KASP primer design now works correctly with Primer3
- Better handling of N-rich regions at chromosome starts

#### Known Limitations
- SNPs at positions <100,000 may fail due to N-rich regions
- Workaround: Use `-l 100` for smaller flanking length or test SNPs >100,000

---

## [2.1.0] - 2026-01-09

### KASP Primers - VCF Filtering and Bash Integration

#### Added
- VCF quality/depth filtering with SNP sorting
  - `--min-qual FLOAT` (default: 20)
  - `--min-depth INT` (default: 5)
  - `--allow-multiallelic` flag
- Smart QUAL/DP field detection
  - Automatically skips quality filtering if fields missing
  - Dynamic logging based on available fields
- Bash-based KASP extractor function (no Python dependency)
  - `extract_kasp_sequence()` replicates Python logic
  - Returns `upstream|downstream|ref|alt` format
- SNP offset control (`--snp-offset INT`)
- Fluorophore tail support (`--use-tails`)

#### Changed
- Output file naming: `{prefix}.txt` instead of `{prefix}_kasp.txt`
- Work directory naming: `{prefix}_results` instead of `{prefix}_kasp_results`
- Improved VCF filtering workflow with quality-based sorting

#### Removed
- `kasp_extractor.py` (integrated into bash)
- Python dependency

---

## [2.0.0] - 2026-01-09

### Generic Primers - INDEL Focus Refactoring

#### Added
- INDEL-specific filtering (>10bp by default)
- `--min-indel-size INT` parameter
- Automatic position file generation from VCF
  - Creates `{prefix}_positions.txt` with filtered INDELs
  - Includes INDEL size column
- Statistics logging:
  - SNPs skipped
  - Small INDELs skipped
  - Large INDELs selected

#### Changed
- **BREAKING:** Script now focuses exclusively on large INDELs
- VCF mode automatically filters for INDELs >10bp
- Position file mode ignores `ref` and `alt` columns
- Simplified workflow (removed variant-specific logic)

#### Removed
- `process_variant()` function
- KASP-related code (moved to separate script)
- Variant-specific primer design

#### Fixed
- Bash error: removed `local` keyword from VCF filtering loop

---

## [1.0.0] - 2025-12-XX

### Initial Release

#### Features
- Generic primer design from VCF or position file
- KASP primer design for SNP genotyping
- Off-target validation with isPCR
- Customizable Primer3 parameters
- Clean tabular output format

---

## Version History Summary

- **v2.2.0** - Proper KASP Primer3 integration
- **v2.1.0** - KASP VCF filtering and bash extractor
- **v2.0.0** - Generic primers INDEL focus
- **v1.0.0** - Initial release
