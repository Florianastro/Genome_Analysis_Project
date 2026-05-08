#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 04:00:00
#SBATCH -J trimmomatic
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/05_rna_quality_control/trimmomatic_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/05_rna_quality_control/trimmomatic_%j.err

# Load required modules
module load Trimmomatic/0.39-Java-17

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  RNA-seq Read Trimming with Trimmomatic"
echo "============================================"

# Create output directories
mkdir -p 06_rna_seq/trimmed_reads
mkdir -p 05_rna_quality_control/trimming_logs

# Define adapter file (TruSeq3 paired-end adapters)
ADAPTERS="$EBROOTTRIMMOMATIC/adapters/TruSeq3-PE.fa"

# Function to trim a single sample
trim_sample() {
    SAMPLE_ID=$1
    CONDITION=$2
    INPUT_DIR=$3
    
    R1="${INPUT_DIR}/${SAMPLE_ID}_1.fastq.gz"
    R2="${INPUT_DIR}/${SAMPLE_ID}_2.fastq.gz"
    
    OUTPUT_DIR="06_rna_seq/trimmed_reads/${CONDITION}"
    mkdir -p $OUTPUT_DIR
    
    echo "Trimming ${CONDITION} sample: ${SAMPLE_ID}..."
    
    trimmomatic PE \
        -threads 4 \
        -phred33 \
        $R1 $R2 \
        ${OUTPUT_DIR}/${SAMPLE_ID}_trimmed_R1.fastq.gz \
        ${OUTPUT_DIR}/${SAMPLE_ID}_trimmed_unpaired_R1.fastq.gz \
        ${OUTPUT_DIR}/${SAMPLE_ID}_trimmed_R2.fastq.gz \
        ${OUTPUT_DIR}/${SAMPLE_ID}_trimmed_unpaired_R2.fastq.gz \
        ILLUMINACLIP:${ADAPTERS}:2:30:10 \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 \
        2>&1 | tee 05_rna_quality_control/trimming_logs/${SAMPLE_ID}_trimming.log
    
    echo "  Done!"
}

# Trim BHI samples (3 replicates)
echo ""
echo "Processing BHI samples..."
trim_sample "ERR1797972" "BHI" "00_raw_data/rna_illumina/RNA-Seq_BH/raw"
trim_sample "ERR1797973" "BHI" "00_raw_data/rna_illumina/RNA-Seq_BH/raw"
trim_sample "ERR1797974" "BHI" "00_raw_data/rna_illumina/RNA-Seq_BH/raw"

# Trim Serum samples (3 replicates)
echo ""
echo "Processing Serum samples..."
trim_sample "ERR1797969" "Serum" "00_raw_data/rna_illumina/RNA-Seq_Serum/raw"
trim_sample "ERR1797970" "Serum" "00_raw_data/rna_illumina/RNA-Seq_Serum/raw"
trim_sample "ERR1797971" "Serum" "00_raw_data/rna_illumina/RNA-Seq_Serum/raw"

echo ""
echo "============================================"
echo "  Trimming Complete!"
echo "============================================"
echo ""
echo "Trimmed files:"
ls -lh 06_rna_seq/trimmed_reads/BHI/
ls -lh 06_rna_seq/trimmed_reads/Serum/
