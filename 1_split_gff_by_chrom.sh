#!/bin/bash
# split_gff_by_chrom.sh
# Usage: ./split_gff_by_chrom.sh annotations.gff3 gff_by_chrom/

GFF="$1"
OUTDIR="${2:-gff_by_chrom}"

mkdir -p "$OUTDIR"

# Extract unique chromosome/scaffold names from gene lines
awk -F'\t' '$3 == "gene" {print $1}' "$GFF" | sort -u | while read CHROM; do
    OUTFILE="${OUTDIR}/${CHROM}.gff3"
    awk -F'\t' -v chrom="$CHROM" '$1 == chrom' "$GFF" > "$OUTFILE"
    COUNT=$(grep -c $'\tgene\t' "$OUTFILE" || true)
    echo "  $CHROM: $COUNT genes -> $OUTFILE"
done

echo "Done. Files in $OUTDIR/"
