# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-01-09

### Added - KASP Primer Script
- VCF quality filtering: `--min-qual` (default: 20) and `--min-depth` (default: 5)
- SNP sorting by quality score (highest quality processed first)
- Bash-based KASP sequence extractor (no Python dependency)
- `--allow-multiallelic` option to include multi-allelic variants
- Detailed filtering statistics in output logs
- Quality range reporting (min/max QUAL scores)

### Changed - KASP Primer Script
- **BREAKING:** VCF mode now filters for SNPs only (biallelic by default)
- VCF mode sorts SNPs by quality before processing
- Integrated kasp_extractor.py logic into pure bash function
- Improved logging with quality scores for each processed SNP
- Updated usage documentation with VCF filtering options

### Removed - KASP Primer Script
- kasp_extractor.py (functionality integrated into kasp_primers.sh)

### Improved - KASP Primer Script
- No external Python dependencies - pure bash implementation
- Better VCF filtering with customizable thresholds
- Clear separation of total variants vs. filtered SNPs
- Enhanced user feedback during processing


## [2.0.0] - 2026-01-09

### Changed
- **BREAKING:** Refactored `generic_primers.sh` to focus on large INDEL primer design
- VCF mode now automatically filters for INDELs >10bp (configurable via `--min-indel-size`)
- VCF mode generates intermediate `{prefix}_positions.txt` file with filtered INDELs
- Position file mode now uses only `chr` and `pos` columns for generic primer design
- Removed variant-specific primer design logic
- Removed KASP primer functionality (moved to separate `kasp_primers.sh` script)
- Simplified workflow: both modes now design generic primers around positions

### Added
- `--min-indel-size` parameter to control INDEL size threshold (default: 10bp)
- Automatic position file generation in VCF mode with columns: chr, pos, ref, alt, indel_size
- Detailed INDEL filtering statistics in output logs
- Comprehensive documentation for adjusting parameters for large INDELs
- Parameter guidelines for different INDEL sizes in README and EXAMPLES

### Removed
- `process_variant()` function (variant-specific primer design)
- KASP primer design from generic_primers.sh
- Support for SNP primer design in generic_primers.sh

### Improved
- Clearer separation between generic and KASP primer workflows
- Better logging with INDEL size information
- Enhanced documentation with practical examples for large INDELs
- Updated EXAMPLES.md with INDEL-focused use cases

### Fixed
- Primer naming now consistent: `primer_chr_pos_index` format
- Output file naming simplified to `{prefix}.txt`


## [1.0.0] - 2026-01-09

### Added
- Initial release of primer design pipeline
- VCF + Region mode for processing variants in genomic regions
- Region file mode for processing specific positions
- Automatic primer type detection (KASP vs General)
- isPCR-based off-target validation
- Customizable Primer3 parameters via command line
- Single tabular output format
- Comprehensive documentation and examples
- MIT License

### Features
- Tool-based approach using samtools, Primer3, and isPCR
- No database creation required
- Clean output structure with main file and detailed results folder
- Support for both SNPs and indels
- Batch processing capability

## [Unreleased]

### Planned
- Support for multiple reference genomes
- Web interface for easier usage
- Integration with variant annotation databases
- Primer ordering integration
- Quality score visualization
