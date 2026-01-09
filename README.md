# Primer Design Pipeline

A comprehensive primer design pipeline with two specialized scripts:
- **generic_primers.sh**: Design primers for large INDELs (>10bp) with off-target validation
- **kasp_primers.sh**: Design KASP (allele-specific) primers for SNP genotyping with quality filtering

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

✅ **Dual Input Modes**
- VCF + Region: Automatically filters for large INDELs (>10bp) and generates position file
- Position File: Process specific genomic positions for generic primer design

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

### Example 1: Design primers from VCF region (INDEL filtering)

```bash
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -o primers_output
```

This will:
1. Filter VCF for INDELs >10bp
2. Generate `primers_output_positions.txt` with filtered INDELs
3. Design generic primers around each INDEL position

### Example 2: Design primers from position file

```bash
bash generic_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f positions.txt \
  -o primers_output
```

### Example 3: Large INDELs with custom parameters

```bash
# For large INDELs (e.g., 70bp deletions), increase flanking length
bash generic_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -l 300 \
  --product-size-max 500 \
  --min-indel-size 50 \
  -o primers_output
```

> **⚠️ IMPORTANT:** For large INDELs, you must increase flanking length (`-l`) and product size (`--product-size-max`) to ensure primers don't fall within the deleted segment. A 70bp deletion typically requires `-l 300` or higher.

## Usage

### Command-Line Options

#### Required (Mode 1: VCF + Region - INDEL Filtering)
```
-v FILE     VCF file (will be filtered for INDELs >10bp)
-r FILE     Reference genome FASTA
-c CHR      Chromosome name
-s INT      Start position
-e INT      End position
-o PREFIX   Output prefix
```

#### Required (Mode 2: Position File)
```
-r FILE     Reference genome FASTA
-f FILE     Position file (chr pos [ref alt])
            Note: ref/alt columns are optional, used only for reference
-o PREFIX   Output prefix
```

#### Optional
```
-l INT              Flanking sequence length [default: 250]
--min-indel-size INT  Minimum INDEL size for VCF filtering [default: 10]
--no-ispcr          Skip isPCR validation (faster)
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

---

## KASP Primer Design (`kasp_primers.sh`)

KASP (Kompetitive Allele-Specific PCR) primer design for SNP genotyping with VCF quality filtering.

### Features

- **VCF Quality Filtering:** Filters SNPs by quality score and read depth
- **SNP Sorting:** Processes highest quality SNPs first
- **Allele-Specific Design:** Creates 2 forward primers (REF/ALT) + 1 common reverse
- **Fluorophore Tails:** Optional FAM/HEX tails for real-time detection
- **SNP Offset Control:** Position SNP at terminal or penultimate position
- **No Python Dependency:** Pure bash implementation with samtools

### Quick Examples

#### Example 1: Basic KASP markers from VCF

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r reference.fa \
  -c chr1 \
  -s 1 \
  -e 50000000 \
  -o kasp_markers
```

**Output:** 3 primers per SNP (Forward_REF, Forward_ALT, Reverse_common)

#### Example 2: With quality filtering

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r reference.fa \
  -c chr1 \
  -s 1 \
  -e 50000000 \
  --min-qual 30 \
  --min-depth 10 \
  -o high_quality_kasp
```

#### Example 3: With fluorophore tails

```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r reference.fa \
  -c chr1 \
  -s 1 \
  -e 50000000 \
  --use-tails \
  --snp-offset 1 \
  -o kasp_with_tails
```

### KASP Command-Line Options

#### Required (Mode 1: VCF + Region)
```
-v FILE     VCF file (filters for SNPs by quality/depth)
-r FILE     Reference genome FASTA
-c CHR      Chromosome
-s INT      Start position
-e INT      End position
-o PREFIX   Output prefix
```

#### Required (Mode 2: Position File)
```
-r FILE     Reference genome FASTA
-f FILE     Position file (chr pos ref alt) - 4 columns required
-o PREFIX   Output prefix
```

#### VCF Filtering Options
```
--min-qual FLOAT        Minimum variant quality score [default: 20]
--min-depth INT         Minimum read depth (DP) [default: 5]
--allow-multiallelic    Allow multi-allelic variants [default: biallelic only]
```

#### KASP-Specific Options
```
-l INT              Flanking length [default: 250]
--use-tails         Add 5' fluorophore tails to forward primers
--tail-fam STR      FAM tail sequence [default: GAAGGTGACCAAGTTCATGCT]
--tail-hex STR      HEX tail sequence [default: GAAGGTCGGAGTCAACGGATT]
--snp-offset INT    SNP position from 3' end (0=terminal, 1=penultimate) [default: 0]
```

### KASP Output Format

File: `{prefix}_kasp.txt`

| Column | Description |
|--------|-------------|
| Marker_name | kasp_chr_pos_index |
| Chr | Chromosome |
| Position | SNP position |
| REF | Reference allele |
| ALT | Alternate allele |
| Primer_type | Forward_REF_allele / Forward_ALT_allele / Reverse_common |
| Sequence | Primer sequence (with or without tail) |
| Length | Primer length (bp) |
| Tm | Melting temperature (°C) |
| GC_Percent | GC content (%) |

### VCF Filtering Workflow

```
VCF File
    ↓
Filter: SNPs only
    ↓
Filter: QUAL ≥ 20, DP ≥ 5
    ↓
Sort by quality (highest first)
    ↓
Design 3 primers per SNP
```

**Example output:**
```
[INFO] Processing VCF region: chr1:1-50000000
[INFO] Filtering: QUAL≥20, DP≥5, SNPs only
[INFO] Found 150 total variants in region
[INFO] Filtered results:
[INFO]   - Total variants: 150
[INFO]   - SNPs passing filters: 45
[INFO]   - Quality range: 20.5 - 99.8 (sorted highest first)
[INFO] Designing KASP markers for 45 SNPs...
```

### SNP Offset Guide

Controls where the SNP sits in the allele-specific forward primer:

- **`--snp-offset 0`** (default): SNP at 3' terminal position
  - Example: `...ACGTACG[T]` (maximum discrimination)
  - Good for: Most SNPs, highest specificity

- **`--snp-offset 1`**: SNP at penultimate (2nd from end) position
  - Example: `...ACGTAC[T]G` (more stable)
  - Good for: Difficult SNPs, better stability

- **`--snp-offset 2`**: SNP at 3rd from end
  - Example: `...ACGTA[T]CG`
  - Good for: Very stable primers needed

---

### Position File Format

The position file supports two formats:

**Format 1: Positions only**
```
chr	pos
1	662351
1	762351
```

**Format 2: Positions with variant information (for reference)**
```
chr	pos	ref	alt
1	862351	ATCGATCGATC	A
1	962351	GTGTGTGTGT	G
1	1062351	C	CTCTCTCTCT
```

**Note:** The `ref` and `alt` columns are used only for documentation/reference (e.g., to track INDEL size). The script designs generic primers around the position regardless of variant information.

You can mix both formats in the same file.

## Output Files

### Main Output: `{prefix}.txt`

Tab-delimited file with all designed primers:

| Column | Description |
|--------|-------------|
| Primer_name | Unique identifier (primer_chr_pos_index) |
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

### Generated Position File (VCF mode): `{prefix}_positions.txt`

When using VCF mode, a position file is automatically generated:

| Column | Description |
|--------|-------------|
| chr | Chromosome |
| pos | Position |
| ref | Reference allele |
| alt | Alternate allele |
| indel_size | Size of INDEL (bp) |

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

### VCF Mode Workflow
```
VCF File
    ↓
Filter for INDELs >10bp
    ↓
Generate Position File
    ↓
Extract Sequences (samtools)
    ↓
Design Generic Primers (Primer3)
    ↓
Validate Off-Targets (isPCR)
    ↓
Generate Report
```

### Position File Mode Workflow
```
Position File
    ↓
Extract Sequences (samtools)
    ↓
Design Generic Primers (Primer3)
    ↓
Validate Off-Targets (isPCR)
    ↓
Generate Report
```

### Primer Design Strategy

1. **INDEL Filtering** (VCF mode): Filters variants for INDELs larger than threshold (default: 10bp)
2. **Sequence Extraction**: Extracts flanking sequences around target positions
3. **Generic Primer Design**: Uses Primer3 to design primers around the position (not variant-specific)
4. **Validation**: Runs isPCR to detect potential off-target amplification
5. **Scoring**: Marks primers with multiple amplification sites as off-target

### Important Notes for Large INDELs

> **⚠️ CRITICAL:** When designing primers for large INDELs, you must adjust parameters to prevent primers from falling within the deleted region:
>
> - **Flanking Length (`-l`)**: Increase to provide adequate sequence for primer design
>   - 10-30bp INDELs: `-l 250` (default)
>   - 30-70bp INDELs: `-l 300`
>   - 70-100bp INDELs: `-l 400` or higher
>
> - **Product Size (`--product-size-max`)**: Increase to accommodate larger amplicons
>   - Default: `300bp`
>   - For large INDELs: `500bp` or higher
>
> **Example for 70bp deletion:**
> ```bash
> bash generic_primers.sh -v test.vcf -r ref.fa -c 1 -s 1 -e 1000000 \
>   -l 300 --product-size-max 500 --min-indel-size 50 -o output
> ```

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
