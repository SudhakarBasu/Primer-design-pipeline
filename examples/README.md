# Example Inputs and Outputs

This directory contains example input files and expected outputs to help you understand how the pipeline works.

## Files

### Input Files

1. **`example_regions.txt`** - Example region file showing both formats:
   - General primers (chr + pos only)
   - KASP primers (chr + pos + ref + alt)

### Output Files

2. **`example_output.txt`** - Sample output from running the pipeline
   - Shows the tabular format with all primer information
   - Demonstrates both KASP and indel primer naming
   - Includes isPCR validation results

## Running the Examples

### Example 1: VCF Mode

```bash
cd ..
bash design_primers.sh \
  -v test.vcf \
  -r Oryza_sativa.chr1.fa \
  -c 1 \
  -s 40000 \
  -e 50000 \
  -o examples/vcf_example
```

### Example 2: Region File Mode

```bash
cd ..
bash design_primers.sh \
  -r Oryza_sativa.chr1.fa \
  -f examples/example_regions.txt \
  -o examples/region_example
```

## Understanding the Output

The output file (`example_output.txt`) contains:

- **Primer_name**: Unique identifier (e.g., `indel_1_41169_0`)
- **Chr**: Chromosome number
- **Position**: Variant position
- **Start/End**: isPCR amplification coordinates
- **Type**: Forward Primer / Reverse Primer
- **Sequence**: Actual primer sequence
- **Length**: Primer length in base pairs
- **Tm**: Melting temperature
- **GC_Percent**: GC content percentage
- **Amplicon_Size**: Expected PCR product size
- **Off_Target**: true/false (multiple amplification sites detected)

## Expected Results

After running the examples, you should see:
- Main output file: `examples/vcf_example_final_output.txt`
- Detailed results: `examples/vcf_example_results/`

Compare your output with `example_output.txt` to verify correct installation.
