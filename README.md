Folder Structure

Current
working-dir/
├── 1_split_by_chrom.sh
├── 2_submit_all.sh
├── omegaplus_pipeline.sh
├── Species_X.vcf.gz
├── Species_X.vcf.gz.tbi
├── genomic.gff
├── gff_by_chrom
└── apptainer/
    ├── OmegaPlus.sif
    └── bcftools-1.16--hfe4b78e_1.sif


Once folder set up run the below:
chmod +x 2_submit_all.sh
chmod +x omegaplus_pipeline.sh

./1_split_gff_by_chrom.sh genomic.gff gff_by_chrom/
./2_submit_all.sh



