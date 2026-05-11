#!/bin/bash

VCF=""
GFF=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -vcf) VCF="$2"; shift ;;
        -gff) GFF="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$VCF" || -z "$GFF" ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 -vcf <vcf_file> -gff <gff_file>"
    exit 1
fi

if [[ ! -f "$VCF" ]]; then
    echo "Error: VCF file not found: $VCF"
    exit 1
fi

if [[ ! -f "$GFF" ]]; then
    echo "Error: GFF file not found: $GFF"
    exit 1
fi

echo "VCF file: $VCF"
echo "GFF file: $GFF"

# Per-chromosome temp file names to avoid race conditions when jobs run in parallel
CHROM_TAG=$(basename "$GFF" .gff3)
GENES_COORD="genes_coord_${CHROM_TAG}.txt"

rm -f "$GENES_COORD"
rm -f skipped_low_snp_genes.txt

### Formatting the GFF: extracting genes, adding 1000 bp flanks ###

awk -F'\t' '$3 == "gene"' "$GFF" | \
awk '{OFS="\t"}{print $1,$4-1000,$5+1000,$1":"$4"-"$5}' | \
awk '{OFS="\t"}{if ($2 > 0) print $1":"$2"-"$3,$4; else print $1":1-"$3,$4;}' \
> "$GENES_COORD"

### OmegaPlus ###

TEMP_RESULTS="temp_${CHROM_TAG}.txt"
rm -f "$TEMP_RESULTS"

regex='(.+)	(.+)'

while read p; do

    if [[ $p =~ $regex ]]; then

        REGION=${BASH_REMATCH[1]}
        GENE=${BASH_REMATCH[2]}
        TEMPVCF="temp_${GENE}.vcf"

        echo "Processing $GENE / $REGION"

        apptainer exec apptainer/bcftools\:1.16--hfe4b78e_1 \
            bcftools view "$VCF" --regions "$REGION" -Ov -o "$TEMPVCF"

        NSNPS=$(grep -vc '^#' "$TEMPVCF")

        if [[ "$NSNPS" -lt 10 ]]; then
            echo -e "${GENE}\t${REGION}\t${NSNPS}" >> skipped_low_snp_genes.txt
            echo "Skipping $GENE: only $NSNPS SNPs"
            rm -f "$TEMPVCF"
            continue
        fi

        apptainer run apptainer/OmegaPlus.sif \
            -input "$TEMPVCF" \
            -minwin 500 \
            -maxwin 100000 \
            -grid 3 \
            -name "output_${GENE}" \
            -seed 12345 \
            -threads 2

        if [[ -f "OmegaPlus_Report.output_${GENE}" ]]; then
            tail -n +3 "OmegaPlus_Report.output_${GENE}" | \
            awk -v var="$GENE" 'BEGIN {OFS="\t"} {print var, $2}' >> "$TEMP_RESULTS"
        else
            echo -e "${GENE}\t${REGION}\tOmegaPlus_failed_no_report" >> skipped_low_snp_genes.txt
            echo "Warning: OmegaPlus report missing for $GENE"
        fi

        rm -f "$TEMPVCF"
        rm -f OmegaPlus_Report*
        rm -f OmegaPlus_Info*

    fi

done < "$GENES_COORD"

### Format results: retain center measurement out of 3 grid measurements ###

if [[ -f "$TEMP_RESULTS" ]]; then
    awk 'NR % 3 == 2' "$TEMP_RESULTS" > "OmegaPlus_${CHROM_TAG}_final_output.txt"
    rm "$TEMP_RESULTS"
else
    echo "No OmegaPlus results were generated."
fi

rm -f "$GENES_COORD"
