#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 02:00:00
#SBATCH -J htseq_count
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/06_rna_seq/counts/htseq_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/06_rna_seq/counts/htseq_%j.err

# ============================================================
# Read Counting with htseq-count
# ============================================================

# Load required modules
module load HTSeq/2.1.2-gfbf-2024a
module load SAMtools/1.22.1-GCC-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  Read Counting with htseq-count"
echo "============================================"
echo ""

# Create output directory
mkdir -p 06_rna_seq/counts

# ============================================================
# Prepare clean GFF file (remove embedded FASTA)
# ============================================================

ANNOTATION_ORIG="03_annotation/prokka/efaecium_E745.gff"
ANNOTATION="03_annotation/prokka/efaecium_E745_clean.gff"

echo "Preparing annotation file..."

# Remove ##FASTA and everything after it, then remove empty lines
sed '/^##FASTA/,$d' "$ANNOTATION_ORIG" | sed '/^$/d' > "$ANNOTATION"

echo "  Original GFF: $(wc -l < $ANNOTATION_ORIG) lines"
echo "  Cleaned GFF:  $(wc -l < $ANNOTATION) lines"
echo ""

# ============================================================
# Count reads for a single sample
# ============================================================

count_sample() {
    SAMPLE_ID=$1
    CONDITION=$2
    
    BAM="06_rna_seq/alignment/${SAMPLE_ID}.bam"
    SORTED_BAM="06_rna_seq/alignment/${SAMPLE_ID}_sorted.bam"
    OUTPUT="06_rna_seq/counts/${SAMPLE_ID}_counts.txt"
    
    echo "Counting ${CONDITION} sample: ${SAMPLE_ID}..."
    
    # Determine which BAM to use
    if [ -f "$SORTED_BAM" ]; then
        INPUT_BAM="$SORTED_BAM"
    elif [ -f "$BAM" ]; then
        INPUT_BAM="$BAM"
    else
        echo "  ERROR: BAM file not found at $BAM or $SORTED_BAM"
        echo "  Run 14_run_bwa_rna.sh first."
        return 1
    fi
    
    # Ensure BAM is sorted by position (htseq-count requires this)
    echo "  Sorting BAM by position..."
    samtools sort -@4 -o ${SORTED_BAM} ${INPUT_BAM}
    samtools index ${SORTED_BAM}
    
    echo "  Running htseq-count..."
    
    # Use htseq-count with output redirect (avoids format issue with -c)
    htseq-count \
        -f bam \
        -r pos \
        -s no \
        -t CDS \
        -i ID \
        ${SORTED_BAM} \
        ${ANNOTATION} \
        > ${OUTPUT} 2> ${OUTPUT}.log
    
    HTSEQ_EXIT=$?
    
    if [ $HTSEQ_EXIT -ne 0 ]; then
        echo "  ERROR: htseq-count failed with exit code $HTSEQ_EXIT"
        echo "  Last 10 lines of log:"
        tail -10 ${OUTPUT}.log
        return 1
    fi
    
    # Check output
    if [ ! -s "$OUTPUT" ]; then
        echo "  ERROR: Output file is empty"
        cat ${OUTPUT}.log
        return 1
    fi
    
    # Quick statistics
    TOTAL_READS=$(awk '{sum+=$2} END {print sum}' $OUTPUT)
    MAPPED_READS=$(grep -v "^__" $OUTPUT | awk '{sum+=$2} END {print sum}')
    GENE_COUNT=$(grep -v "^__" $OUTPUT | grep -c .)
    
    echo "  Total counts:    $TOTAL_READS"
    echo "  Mapped to genes: $MAPPED_READS"
    echo "  Genes detected:  $GENE_COUNT"
    echo "  Output: $OUTPUT"
    echo ""
    
    return 0
}

# ============================================================
# Count all samples
# ============================================================

echo "============================================"
echo "  Processing BHI samples"
echo "============================================"
count_sample "ERR1797972" "BHI"
count_sample "ERR1797973" "BHI"
count_sample "ERR1797974" "BHI"

echo "============================================"
echo "  Processing Serum samples"
echo "============================================"
count_sample "ERR1797969" "Serum"
count_sample "ERR1797970" "Serum"
count_sample "ERR1797971" "Serum"

echo "============================================"
echo "  Read Counting Complete!"
echo "============================================"
echo ""
echo "Count files:"
ls -lh 06_rna_seq/counts/*_counts.txt 2>/dev/null || echo "  No count files found"
