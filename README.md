# Selective Sweeps Pipeline (OmegaPlus)

## Overview
Scans all genes in a genome for signals of selective sweeps using OmegaPlus, parallelised by chromosome via SLURM.

## Requirements
- Apptainer/Singularity
- SLURM job scheduler
- A tabix-indexed VCF (`tabix -p vcf Species_X.vcf.gz`)

## Directory Structure
```
working-dir/
├── 1_split_gff_by_chrom.sh      # Step 1: split GFF by chromosome
├── 2_submit_all.sh              # Step 2: submit parallel SLURM jobs
├── omegaplus_pipeline.sh        # Called by each SLURM job
├── Species_X.vcf.gz             # Input VCF
├── Species_X.vcf.gz.tbi         # VCF tabix index
├── genomic.gff                  # Input GFF
├── gff_by_chrom/                # Created by Step 1
└── apptainer/
    ├── OmegaPlus.sif
    └── bcftools:1.16--hfe4b78e_1
```

## Usage

### 1. Set permissions
```bash
chmod +x omegaplus_pipeline.sh
chmod +x 1_split_gff_by_chrom.sh
chmod +x 2_submit_all.sh
```

### 2. Split GFF by chromosome
```bash
./1_split_gff_by_chrom.sh genomic.gff gff_by_chrom/
```
Organelles (mitochondria, chloroplast) can be removed from `gff_by_chrom/` at this point if not needed.

### 3. Submit jobs
```bash
./2_submit_all.sh
```
This creates a `runs/` directory with one subdirectory per chromosome, each submitted as an independent SLURM job running in parallel.

### 4. Monitor
```bash
# Check job queue
squeue -u $USER

# Watch a specific chromosome
tail -f runs/CP093343.1/logs/omega_CP093343.1-*.out
```

## Output
Each chromosome produces in its `runs/CHROM/` directory:
- `OmegaPlus_CHROM_final_output.txt` — omega scores per gene (centre grid point)
- `skipped_low_snp_genes.txt` — genes skipped due to fewer than 10 SNPs in region

### Merge all chromosomes after completion
```bash
cat runs/*/OmegaPlus_*_final_output.txt > OmegaPlus_all_chroms.txt
cat runs/*/skipped_low_snp_genes.txt > skipped_all_chroms.txt
```

## Notes
- Genes with fewer than 10 SNPs in their region (± 1000 bp flanks) are skipped to prevent OmegaPlus from crashing
- OmegaPlus parameters: `-minwin 500 -maxwin 100000 -grid 3 -seed 12345 -threads 2`
- Do not filter VCF by MAF; singletons can be removed
