#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 03:00:00
#SBATCH -J bwa_rna
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/06_rna_seq/alignment/bwa_rna_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/06_rna_seq/alignment/bwa_rna_%j.err

# ============================================================
# RNA-seq Alignment with BWA MEM
# ============================================================

# Load required modules
module load BWA/0.7.19-GCCcore-13.3.0
module load SAMtools/1.22.1-GCC-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  RNA-seq Alignment with BWA MEM"
echo "============================================"
echo ""

# Create output directory
mkdir -p 06_rna_seq/alignment

# Define reference genome (polished assembly)
REFERENCE="02_assembly/polishing/efaecium_E745_polished.fasta"

# Check if reference exists
if [ ! -f "$REFERENCE" ]; then
    echo "ERROR: Reference genome not found at $REFERENCE"
    exit 1
fi

# Index reference if needed
if [ ! -f "${REFERENCE}.bwt" ]; then
    echo "Indexing reference genome..."
    bwa index $REFERENCE
else
    echo "Reference index already exists."
fi

echo ""

# ============================================================
# Align a single sample (step by step, avoiding pipe failures)
# ============================================================

align_sample() {
    SAMPLE_ID=$1
    CONDITION=$2
    
    TRIM_DIR="06_rna_seq/trimmed_reads/${CONDITION}"
    R1="${TRIM_DIR}/${SAMPLE_ID}_trimmed_R1.fastq.gz"
    R2="${TRIM_DIR}/${SAMPLE_ID}_trimmed_R2.fastq.gz"
    
    SAM_FILE="06_rna_seq/alignment/${SAMPLE_ID}.sam"
    BAM_FILE="06_rna_seq/alignment/${SAMPLE_ID}.bam"
    SORTED_BAM="06_rna_seq/alignment/${SAMPLE_ID}_sorted.bam"
    
    echo "Aligning ${CONDITION} sample: ${SAMPLE_ID}..."
    
    # Check input files
    if [ ! -f "$R1" ]; then
        echo "  ERROR: R1 file not found: $R1"
        return 1
    fi
    if [ ! -f "$R2" ]; then
        echo "  ERROR: R2 file not found: $R2"
        return 1
    fi
    
    # Step 1: BWA alignment (SAM output)
    echo "  Step 1: BWA MEM alignment..."
    bwa mem -t 4 -M $REFERENCE $R1 $R2 > $SAM_FILE 2> ${SAM_FILE}.bwa_log
    
    BWA_EXIT=$?
    if [ $BWA_EXIT -ne 0 ]; then
        echo "  ERROR: BWA failed with exit code $BWA_EXIT"
        cat ${SAM_FILE}.bwa_log
        return 1
    fi
    
    if [ ! -s "$SAM_FILE" ]; then
        echo "  ERROR: SAM file is empty"
        return 1
    fi
    
    SAM_SIZE=$(du -h $SAM_FILE | cut -f1)
    echo "  SAM file size: $SAM_SIZE"
    
    # Step 2: Convert SAM to BAM
    echo "  Step 2: Converting SAM to BAM..."
    samtools view -bS -h $SAM_FILE > $BAM_FILE 2> ${BAM_FILE}.view_log
    
    VIEW_EXIT=$?
    if [ $VIEW_EXIT -ne 0 ]; then
        echo "  ERROR: samtools view failed with exit code $VIEW_EXIT"
        cat ${BAM_FILE}.view_log
        return 1
    fi
    
    # Remove SAM to save space
    rm -f $SAM_FILE ${SAM_FILE}.bwa_log
    
    # Step 3: Sort BAM
    echo "  Step 3: Sorting BAM..."
    samtools sort -@4 -o $SORTED_BAM $BAM_FILE 2> ${SORTED_BAM}.sort_log
    
    SORT_EXIT=$?
    if [ $SORT_EXIT -ne 0 ]; then
        echo "  ERROR: samtools sort failed with exit code $SORT_EXIT"
        cat ${SORTED_BAM}.sort_log
        return 1
    fi
    
    # Remove unsorted BAM
    rm -f $BAM_FILE ${BAM_FILE}.view_log
    
    # Rename sorted BAM to final name
    mv $SORTED_BAM $BAM_FILE
    rm -f ${SORTED_BAM}.sort_log
    
    # Step 4: Index BAM
    echo "  Step 4: Indexing BAM..."
    samtools index $BAM_FILE
    
    INDEX_EXIT=$?
    if [ $INDEX_EXIT -ne 0 ]; then
        echo "  ERROR: samtools index failed with exit code $INDEX_EXIT"
        return 1
    fi
    
    # Step 5: Statistics
    echo "  Step 5: Generating statistics..."
    echo "  ----------------------------------------"
    samtools flagstat $BAM_FILE
    echo "  ----------------------------------------"
    
    BAM_SIZE=$(du -h $BAM_FILE | cut -f1)
    echo "  BAM file size: $BAM_SIZE"
    echo "  Done!"
    echo ""
    
    return 0
}

# ============================================================
# Align all samples
# ============================================================

FAILED_SAMPLES=""

echo "============================================"
echo "  Aligning BHI samples"
echo "============================================"
echo ""

for SAMPLE in ERR1797972 ERR1797973 ERR1797974; do
    align_sample "$SAMPLE" "BHI"
    if [ $? -ne 0 ]; then
        FAILED_SAMPLES="$FAILED_SAMPLES $SAMPLE(BHI)"
    fi
done

echo "============================================"
echo "  Aligning Serum samples"
echo "============================================"
echo ""

for SAMPLE in ERR1797969 ERR1797970 ERR1797971; do
    align_sample "$SAMPLE" "Serum"
    if [ $? -ne 0 ]; then
        FAILED_SAMPLES="$FAILED_SAMPLES $SAMPLE(Serum)"
    fi
done

echo "============================================"
echo "  RNA-seq Alignment Complete!"
echo "============================================"
echo ""

if [ -n "$FAILED_SAMPLES" ]; then
    echo "WARNING: The following samples failed:"
    echo "$FAILED_SAMPLES"
else
    echo "All samples aligned successfully!"
fi

echo ""
echo "Output files:"
ls -lh 06_rna_seq/alignment/*.bam 2>/dev/null
ls -lh 06_rna_seq/alignment/*.bam.bai 2>/dev/null
