# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
