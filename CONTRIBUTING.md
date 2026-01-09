# Contributing to Primer Design Pipeline

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, tool versions)
- Example data if possible

### Suggesting Features

Feature requests are welcome! Please:
- Check if the feature already exists
- Describe the use case clearly
- Explain why it would be useful
- Provide examples if applicable

### Pull Requests

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your fork
7. Open a pull request

### Code Style

- Use clear variable names
- Add comments for complex logic
- Follow existing code structure
- Test with example data

### Testing

Before submitting:
- Test with provided example data
- Verify output format matches specification
- Check edge cases (empty input, large files, etc.)
- Ensure backward compatibility

## Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/primer-design-pipeline.git
cd primer-design-pipeline

# Install dependencies
conda install -c bioconda samtools primer3 ucsc-ispcr

# Test
bash design_primers.sh -v test.vcf -r Oryza_sativa.chr1.fa -c 1 -s 40000 -e 50000 -o test
```

## Questions?

Feel free to open an issue for any questions about contributing!
