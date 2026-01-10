# Primer Design Pipeline

A comprehensive primer design pipeline with two specialized scripts for molecular biology applications.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🧬 Scripts

### 1. **generic_primers.sh** - Large INDEL Primer Design
Design primers for large insertions/deletions (>10bp) with off-target validation.

### 2. **kasp_primers.sh** - KASP Marker Design  
Design allele-specific primers for SNP genotyping using KASP technology.

---

## 📋 Features

### Generic Primers (`generic_primers.sh`)
- ✅ **INDEL Filtering:** Automatically filters VCF for large INDELs (>10bp)
- ✅ **Position File Generation:** Creates intermediate position file for review
- ✅ **Off-Target Validation:** Uses isPCR for realistic amplification simulation
- ✅ **Flexible Input:** VCF+Region or Position file modes
- ✅ **Clean Output:** Single tabular file with all primers

### KASP Primers (`kasp_primers.sh`)
- ✅ **SNP-Specific:** Designs allele-specific primers for SNP genotyping
- ✅ **VCF Quality Filtering:** Filters by QUAL and depth (optional)
- ✅ **Fluorophore Tails:** Optional FAM/HEX tails for real-time detection
- ✅ **SNP Offset Control:** Position SNP at terminal or penultimate position
- ✅ **Pure Bash:** No Python dependencies

---

## 🚀 Quick Start

### Installation

#### Prerequisites
```bash
# Using conda (recommended)
conda install -c bioconda samtools primer3 ucsc-ispcr

# Or install individually
conda install -c bioconda samtools
conda install -c bioconda primer3
conda install -c bioconda ucsc-ispcr  # Only for generic_primers.sh
```

#### Clone Repository
```bash
git clone https://github.com/yourusername/primer-design-pipeline.git
cd primer-design-pipeline
```

### Example Usage

#### Generic Primers (INDELs)
```bash
bash generic_primers.sh \
  -v test.vcf \
  -r reference.fa \
  -c chr1 \
  -s 1000000 \
  -e 2000000 \
  -o indel_primers
```

#### KASP Primers (SNPs)
```bash
bash kasp_primers.sh \
  -v snps.vcf \
  -r reference.fa \
  -c chr1 \
  -s 1000000 \
  -e 2000000 \
  -o kasp_markers
```

---

## 📖 Documentation

- **[EXAMPLES.md](EXAMPLES.md)** - Detailed usage examples
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines

---

## 💡 Key Differences

| Feature | generic_primers.sh | kasp_primers.sh |
|---------|-------------------|-----------------|
| **Target** | Large INDELs (>10bp) | SNPs only |
| **Primers** | 2 generic (F+R) | 3 allele-specific (2F+1R) |
| **Filtering** | INDEL size | Quality + Depth (optional) |
| **Off-Target** | isPCR validation | Not included |
| **Output** | {prefix}.txt | {prefix}.txt |
| **Special** | Position file generation | Fluorophore tails, SNP offset |

---

## 📊 Output Format

Both scripts produce tab-delimited output files:

```
Primer_name  Chr  Position  Start  End  Type  Sequence  Length  Tm  GC_Percent  Amplicon_Size  Off_Target
```

**Generic Primers:** 2 rows per INDEL (Forward + Reverse)  
**KASP Primers:** 3 rows per SNP (Forward_REF + Forward_ALT + Reverse_common)

---

## ⚠️ Known Limitations

### KASP Primers
- **Early Chromosome Positions:** SNPs at positions <100,000 may fail due to N-rich regions at chromosome starts
- **Solution:** Use SNPs at positions >100,000 or reduce flanking length (`-l 100`)
- **INDEL Support:** Only works for SNPs (single base changes), not INDELs

### Generic Primers
- **Large INDELs:** For very large INDELs (>50bp), increase flanking length (`-l 300`) and product size (`--product-size-max 500`)

---

## 🔧 Advanced Usage

### Generic Primers

**Custom INDEL size threshold:**
```bash
bash generic_primers.sh -v test.vcf -r ref.fa -c chr1 -s 1 -e 1000000 \
  --min-indel-size 50 -o large_indels
```

**From position file:**
```bash
bash generic_primers.sh -r ref.fa -f positions.txt -o primers
```

### KASP Primers

**With quality filtering:**
```bash
bash kasp_primers.sh -v snps.vcf -r ref.fa -c chr1 -s 1000000 -e 2000000 \
  --min-qual 30 --min-depth 10 -o high_quality_kasp
```

**With fluorophore tails:**
```bash
bash kasp_primers.sh -v snps.vcf -r ref.fa -c chr1 -s 1000000 -e 2000000 \
  --use-tails --snp-offset 1 -o kasp_with_tails
```

**From position file (4 columns required):**
```bash
# Create position file: chr pos ref alt
echo -e "chr1\t1000000\tA\tG" > kasp_positions.txt

bash kasp_primers.sh -r ref.fa -f kasp_positions.txt -o kasp_from_file
```

---

## 📁 Repository Structure

```
primer-design-pipeline/
├── generic_primers.sh       # INDEL primer design script
├── kasp_primers.sh          # KASP marker design script
├── test.vcf                 # Example VCF file
├── position.txt             # Example position file
├── README.md                # This file
├── EXAMPLES.md              # Detailed examples
├── CHANGELOG.md             # Version history
├── CONTRIBUTING.md          # Contribution guidelines
├── LICENSE                  # MIT License
└── examples/                # Example data and commands
    ├── README.md
    └── EXAMPLE_COMMANDS.md
```

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📧 Contact

For questions or issues, please open an issue on GitHub.

---

## 🙏 Acknowledgments

- **Primer3** - Primer design engine
- **samtools** - Sequence extraction
- **isPCR** - Off-target validation (generic primers)

---

## 📚 Citation

If you use this pipeline in your research, please cite:

```
[Your Citation Here]
```
