#!/bin/bash
# Run from Carrot_dom_chromosomes/

WORKDIR=$(pwd)
VCF="${WORKDIR}/Daucus_carota_domesticate_PRJNA291976_filtered.vcf.gz"
GFF_DIR="${WORKDIR}/gff_by_chrom"

for GFF_FILE in "${GFF_DIR}"/CP*.gff3; do
    CHROM=$(basename "$GFF_FILE" .gff3)
    RUNDIR="${WORKDIR}/runs/${CHROM}"

    # Set up run directory
    mkdir -p "${RUNDIR}/logs"

    # Symlink apptainer images and pipeline script
    ln -sf "${WORKDIR}/apptainer" "${RUNDIR}/apptainer"
    ln -sf "${WORKDIR}/omegaplus_pipeline.sh" "${RUNDIR}/omegaplus_pipeline.sh"

    sbatch \
        --job-name="omega_${CHROM}" \
        --time=0-72:00 \
        --cpus-per-task=2 \
        --mem-per-cpu=4G \
        --account=def-yeaman \
        --output="${RUNDIR}/logs/omega_${CHROM}-%j.out" \
        --error="${RUNDIR}/logs/omega_${CHROM}-%j.err" \
        --mail-user=ahmccorm@hawaii.edu \
        --mail-type=FAIL \
        --wrap="cd ${RUNDIR} && module load apptainer && \
                ./omegaplus_pipeline.sh \
                    -vcf ${VCF} \
                    -gff ${GFF_FILE}"

    echo "Submitted: $CHROM -> $RUNDIR"
done
