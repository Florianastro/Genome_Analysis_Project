#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 02:00:00
#SBATCH -J tnseq
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/07_tn_seq/tnseq_analysis_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/07_tn_seq/tnseq_analysis_%j.err

# ============================================================
# Tn-seq Analysis: Conditionally Essential Genes
# Based on Zhang et al. (2017)
# ============================================================

# Load required modules
module load BWA/0.7.19-GCCcore-13.3.0
module load SAMtools/1.22.1-GCC-13.3.0
module load BEDTools/2.31.1-GCC-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  Tn-seq Analysis Pipeline"
echo "============================================"

# Create output directories
mkdir -p 07_tn_seq/trimmed_reads
mkdir -p 07_tn_seq/mapped_reads
mkdir -p 07_tn_seq/counts
mkdir -p 07_tn_seq/essential_genes

# Define reference genome
REFERENCE="02_assembly/polishing/efaecium_E745_polished.fasta"

# Index reference if needed
if [ ! -f "${REFERENCE}.bwt" ]; then
    echo "Indexing reference genome..."
    bwa index $REFERENCE
fi

# ============================================================
# Step 1: Process Tn-seq reads
# ============================================================

echo "Step 1: Processing Tn-seq reads..."

# Function to process a single Tn-seq sample
process_tnseq() {
    SAMPLE=$1
    CONDITION=$2
    
    INPUT="00_raw_data/tn_seq/Tn-Seq_${CONDITION}/trim_${SAMPLE}_pass.fastq.gz"
    OUTPUT="07_tn_seq/mapped_reads/${SAMPLE}.bam"
    
    echo "  Processing $CONDITION sample: $SAMPLE"
    
    if [ ! -f "$INPUT" ]; then
        echo "    WARNING: Input file not found: $INPUT"
        return
    fi
    
    # Map reads to genome
    bwa mem -t 4 $REFERENCE $INPUT | \
        samtools view -bS -F 4 - | \
        samtools sort -@4 -o $OUTPUT -
    
    # Index BAM
    samtools index $OUTPUT
    
    # Count mapped reads
    MAPPED=$(samtools flagstat $OUTPUT | head -1 | cut -d' ' -f1)
    echo "    Mapped reads: $MAPPED"
}

# Process BHI samples (3 replicates)
echo ""
echo "Processing BHI samples..."
process_tnseq "ERR1801012" "BHI"
process_tnseq "ERR1801013" "BHI"
process_tnseq "ERR1801014" "BHI"

# Process Heat-inactivated Serum samples (3 replicates, used in paper)
echo ""
echo "Processing Heat-inactivated Serum samples..."
process_tnseq "ERR1801009" "HSerum"
process_tnseq "ERR1801010" "HSerum"
process_tnseq "ERR1801011" "HSerum"

# Process Native Serum samples (3 replicates, optional)
echo ""
echo "Processing Native Serum samples..."
process_tnseq "ERR1801006" "Serum"
process_tnseq "ERR1801007" "Serum"
process_tnseq "ERR1801008" "Serum"

# ============================================================
# Step 2: Create gene position file
# ============================================================

echo ""
echo "Step 2: Creating gene position file..."

# Extract gene positions from Prokka GFF
if [ -f "03_annotation/prokka/efaecium_E745.gff" ]; then
    grep -v "^#" 03_annotation/prokka/efaecium_E745.gff | \
        awk '$3 == "gene"' | \
        awk -F'\t' '{print $1"\t"$4"\t"$5"\t"$9}' | \
        sed 's/.*ID=\([^;]*\).*/\1/' \
        > 07_tn_seq/counts/gene_positions.bed
    
    GENE_COUNT=$(wc -l < 07_tn_seq/counts/gene_positions.bed)
    echo "  Extracted $GENE_COUNT gene positions"
else
    echo "  WARNING: Prokka GFF file not found"
fi

# ============================================================
# Step 3: Count insertions per gene
# ============================================================

echo ""
echo "Step 3: Counting insertions per gene..."

# Function to count insertions for a sample
count_insertions() {
    SAMPLE=$1
    CONDITION=$2
    
    BAM="07_tn_seq/mapped_reads/${SAMPLE}.bam"
    OUTPUT="07_tn_seq/counts/${SAMPLE}_per_gene_counts.txt"
    
    if [ ! -f "$BAM" ] || [ ! -f "07_tn_seq/counts/gene_positions.bed" ]; then
        return
    fi
    
    echo "  Counting insertions for $SAMPLE ($CONDITION)..."
    
    # Get insertion positions
    samtools view $BAM | \
        awk '{print $3"\t"$4}' | \
        sort -k1,1 -k2,2n | \
        uniq -c | \
        awk '{print $2"\t"$3"\t"$3"\t"$1}' \
        > 07_tn_seq/counts/${SAMPLE}_insertions.bed
    
    # Count insertions per gene
    bedtools intersect \
        -a 07_tn_seq/counts/gene_positions.bed \
        -b 07_tn_seq/counts/${SAMPLE}_insertions.bed \
        -c \
        -F 0.9 \
        > $OUTPUT
    
    echo "    Done!"
}

# Count insertions for each sample
for SAMPLE in ERR1801012 ERR1801013 ERR1801014 ERR1801009 ERR1801010 ERR1801011 ERR1801006 ERR1801007 ERR1801008; do
    # Determine condition from sample ID
    case $SAMPLE in
        ERR180101[2-4]) CONDITION="BHI" ;;
        ERR180100[9-11]) CONDITION="HSerum" ;;
        ERR180100[6-8]) CONDITION="Serum" ;;
        *) CONDITION="Unknown" ;;
    esac
    
    count_insertions $SAMPLE $CONDITION
done

# ============================================================
# Step 4: Identify conditionally essential genes
# ============================================================

echo ""
echo "Step 4: Identifying conditionally essential genes..."
echo ""

# Create a simple R script for essential gene analysis
cat > 07_tn_seq/essential_genes/identify_essential_genes.R << 'REOF'
#!/usr/bin/env Rscript

# Load count data
bhi_files <- list.files("../counts/", pattern = "ERR180101[2-4]_per_gene_counts.txt", full.names = TRUE)
serum_files <- list.files("../counts/", pattern = "ERR180100[9-11]_per_gene_counts.txt", full.names = TRUE)

if (length(bhi_files) > 0 && length(serum_files) > 0) {
    # Read and combine BHI counts
    bhi_counts <- do.call(cbind, lapply(bhi_files, function(f) {
        read.table(f, header = FALSE)[, 4]
    }))
    bhi_mean <- rowMeans(bhi_counts)
    
    # Read and combine Serum counts
    serum_counts <- do.call(cbind, lapply(serum_files, function(f) {
        read.table(f, header = FALSE)[, 4]
    }))
    serum_mean <- rowMeans(serum_counts)
    
    # Gene names
    gene_names <- read.table(bhi_files[1], header = FALSE)[, 4]
    
    # Calculate fold change
    fold_change <- (serum_mean + 1) / (bhi_mean + 1)
    
    # Create results
    results <- data.frame(
        gene = gene_names,
        BHI_mean = bhi_mean,
        Serum_mean = serum_mean,
        FoldChange = fold_change,
        stringsAsFactors = FALSE
    )
    
    # Genes depleted in serum = conditionally essential
    results$essential <- ifelse(results$FoldChange < 0.5 & results$BHI_mean > 10, 
                                  "Conditionally Essential", "Not Essential")
    
    # Sort
    results <- results[order(results$FoldChange), ]
    
    # Save
    write.csv(results, "essential_genes_results.csv", row.names = FALSE)
    
    # Summary
    n_essential <- sum(results$essential == "Conditionally Essential")
    cat("Total genes analyzed:", nrow(results), "\n")
    cat("Conditionally essential genes:", n_essential, "\n")
} else {
    cat("Count files not found. Please run the Tn-seq processing first.\n")
}
REOF

echo "R script created for essential gene analysis."
echo "Run with: Rscript 07_tn_seq/essential_genes/identify_essential_genes.R"

# ============================================================
# Step 5: Check for key genes from the paper
# ============================================================

echo ""
echo "============================================"
echo "  Key Genes from Zhang et al. (2017)"
echo "============================================"
echo ""
echo "Conditionally essential genes expected:"
echo "  Nucleotide biosynthesis:"
echo "    - pyrK_2 (pyrimidine)"
echo "    - pyrF (pyrimidine)"
echo "    - purD (purine)"
echo "    - purH (purine)"
echo "    - purL (purine)"
echo "    - purQ (purine)"
echo "    - purC (purine)"
echo "    - guaB (purine)"
echo "    - purA (purine)"
echo ""
echo "  Carbohydrate metabolism:"
echo "    - manY_2 (PTS subunit)"
echo "    - manZ_3 (PTS subunit)"
echo "    - ptsI (PTS enzyme)"
echo ""
echo "  Cell wall remodeling:"
echo "    - ddcP"
echo "    - ldtfm"
echo "    - mgs"
echo "    - clsA_1"
echo "    - lytA_2"
echo ""

echo "============================================"
echo "  Tn-seq Analysis Complete!"
echo "============================================"
echo ""
echo "To complete the analysis:"
echo "  1. Run the R script: Rscript 07_tn_seq/essential_genes/identify_essential_genes.R"
echo "  2. Compare with paper results (Zhang et al. 2017, Fig. 3)"
echo "  3. Check if key genes above are identified as conditionally essential"
