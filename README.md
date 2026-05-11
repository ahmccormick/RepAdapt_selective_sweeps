Folder Structure

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

    

Once folder set up run the below:
chmod +x 2_submit_all.sh
chmod +x omegaplus_pipeline.sh

./1_split_gff_by_chrom.sh genomic.gff gff_by_chrom/
./2_submit_all.sh



