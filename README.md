# Primer Design Pipeline

A lightweight, tool-based primer design pipeline for SNPs and indels with off-target validation using isPCR.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

✅ **Dual Input Modes**
- VCF + Region: Process all variants in a genomic region
- Region File: Process specific positions with or without variant information

✅ **Automatic Primer Type Detection**
- KASP primers for SNPs (with allele information)
- General primers for indels or positions without variants

✅ **Off-Target Validation**
- Uses isPCR for realistic PCR amplification simulation
- No database creation required
- Detects multiple amplification sites

✅ **Customizable Parameters**
- All Primer3 parameters configurable via command line
- Sensible defaults for immediate use

✅ **Clean Output**
- Single tabular output file with all primers
- Detailed intermediate files in separate folder
- Easy to parse and integrate into pipelines

## Installation

### Prerequisites

Install required bioinformatics tools:

```bash
# Using conda (recommended)
conda install -c bioconda samtools primer3 ucsc-ispcr

# Or install individually
conda install -c bioconda samtools
conda install -c bioconda primer3
conda install -c bioconda ucsc-ispcr
```

### Clone Repository

```bash
git clone https://github.com/yourusername/primer-design-pipeline.git
cd primer-design-pipeline
```

## Quick Start

### Example 1: Design primers from VCF region

```bash
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -o primers_output
```

### Example 2: Design primers from region file

```bash
bash design_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f regions.txt \
  -o primers_output
```

### Example 3: Custom Primer3 parameters

```bash
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  --primer-tm-opt 62.0 \
  --product-size-max 250 \
  -o primers_output
```

## Usage

### Command-Line Options

#### Required (Mode 1: VCF + Region)
```
-v FILE     VCF file
-r FILE     Reference genome FASTA
-c CHR      Chromosome name
-s INT      Start position
-e INT      End position
-o PREFIX   Output prefix
```

#### Required (Mode 2: Region File)
```
-r FILE     Reference genome FASTA
-f FILE     Region file (see format below)
-o PREFIX   Output prefix
```

#### Optional
```
-l INT      Flanking sequence length [default: 250]
--no-ispcr  Skip isPCR validation (faster)
```

#### Primer3 Parameters (Optional)
```
--primer-size-min INT       Min primer size [default: 18]
--primer-size-opt INT       Optimal primer size [default: 20]
--primer-size-max INT       Max primer size [default: 25]
--primer-tm-min FLOAT       Min Tm [default: 57.0]
--primer-tm-opt FLOAT       Optimal Tm [default: 60.0]
--primer-tm-max FLOAT       Max Tm [default: 63.0]
--primer-gc-min FLOAT       Min GC% [default: 40.0]
--primer-gc-max FLOAT       Max GC% [default: 60.0]
--product-size-min INT      Min product size [default: 100]
--product-size-max INT      Max product size [default: 300]
--num-return INT            Number of primers to return [default: 3]
```

### Region File Format

The region file supports two formats:

**Format 1: General primers (no variant information)**
```
chr	pos
1	662351
1	762351
```

**Format 2: KASP primers (with variant information)**
```
chr	pos	ref	alt
1	862351	A	G
1	962351	GT	G
1	1062351	C	CT
```

You can mix both formats in the same file.

## Output Files

### Main Output: `{prefix}_final_output.txt`

Tab-delimited file with all designed primers:

| Column | Description |
|--------|-------------|
| Primer_name | Unique identifier (kasp/indel_chr_pos_index) |
| Chr | Chromosome |
| Position | Variant position |
| Start | isPCR amplification start coordinate |
| End | isPCR amplification end coordinate |
| Type | Forward Primer / Reverse Primer |
| Sequence | Primer sequence (5' to 3') |
| Length | Primer length (bp) |
| Tm | Melting temperature (°C) |
| GC_Percent | GC content (%) |
| Amplicon_Size | Expected PCR product size (bp) |
| Off_Target | true if multiple amplification sites detected |

### Detailed Results: `{prefix}_results/`

Contains intermediate files:
- `variants.txt` - Extracted variants from VCF
- `seq.fa` - Extracted sequences
- `p3_input.txt` - Primer3 input
- `p3_output.txt` - Primer3 output
- `ispcr_input.txt` - isPCR input
- `ispcr_output.txt` - isPCR results

## Example Data

Test data is provided in the `examples/` directory:

- `test.vcf` - Sample VCF file with SNPs and indels (in root)
- `Oryza_sativa.chr1.fa` - Rice chromosome 1 reference sequence (in root)
- `examples/example_regions.txt` - Example region file
- `examples/example_output.txt` - Sample output for reference

See [examples/README.md](examples/README.md) for detailed usage examples.

## How It Works

```
Input (VCF/Region File)
         ↓
Extract Sequences (samtools)
         ↓
Design Primers (Primer3)
         ↓
Validate Off-Targets (isPCR)
         ↓
Generate Report
```

### Primer Design Strategy

1. **Sequence Extraction**: Extracts flanking sequences around variant positions
2. **Primer Design**: Uses Primer3 with optimized parameters for PCR
3. **Validation**: Runs isPCR to detect potential off-target amplification
4. **Scoring**: Marks primers with multiple amplification sites as off-target

### Off-Target Detection

- **false**: Single amplification site (specific)
- **true**: Multiple amplification sites (non-specific)

## Advantages Over Other Tools

| Feature | This Pipeline | Python-based | BLAST-based |
|---------|--------------|--------------|-------------|
| **Speed** | ✅ Fast | ⚠️ Slower | ⚠️ Slow |
| **Database** | ✅ Not needed | ✅ Not needed | ❌ Required |
| **Validation** | ✅ isPCR (realistic) | ⚠️ Varies | ⚠️ Sequence alignment |
| **Maintenance** | ✅ Tool updates independent | ❌ Code updates needed | ❌ Database updates needed |
| **Flexibility** | ✅ Easy to customize | ⚠️ Code changes | ⚠️ Limited |

## Troubleshooting

### "samtools: command not found"
```bash
conda install -c bioconda samtools
```

### "primer3_core: command not found"
```bash
conda install -c bioconda primer3
```

### "isPcr: command not found"
```bash
conda install -c bioconda ucsc-ispcr
# Or skip validation with --no-ispcr flag
```

### "No primers designed"
- Check if variant exists in VCF
- Try increasing flanking length (`-l 300`)
- Adjust Primer3 parameters
- Check sequence quality around variant

### "Reference mismatch"
- Ensure VCF and FASTA are from the same genome version
- Check chromosome naming (chr1 vs 1)

## Citation

If you use this pipeline in your research, please cite:

**Tools used:**
- **samtools**: Li H, et al. (2009) The Sequence Alignment/Map format and SAMtools. Bioinformatics 25(16):2078-9
- **Primer3**: Untergasser A, et al. (2012) Primer3--new capabilities and interfaces. Nucleic Acids Res. 40(15):e115
- **isPCR**: Kent WJ (2002) BLAT--the BLAST-like alignment tool. Genome Res. 12(4):656-64

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or issues, please open an issue on GitHub.

## Acknowledgments

- Primer3 team for the excellent primer design tool
- UCSC Genome Browser team for isPCR
- Samtools developers
