#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -J rna_qc_before
#SBATCH --mem=8G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/05_rna_quality_control/fastqc_before_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/05_rna_quality_control/fastqc_before_%j.err

# Load required modules
module load FastQC/0.12.1-Java-17

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  RNA-seq Quality Control - Before Trimming"
echo "============================================"

# Create output directories
mkdir -p 05_rna_quality_control/fastqc_before/BHI
mkdir -p 05_rna_quality_control/fastqc_before/Serum

# Run FastQC on BHI replicates
echo "Running FastQC on BHI samples..."
fastqc -o 05_rna_quality_control/fastqc_before/BHI/ \
       00_raw_data/rna_illumina/RNA-Seq_BH/raw/*.fastq.gz

# Run FastQC on Serum replicates
echo "Running FastQC on Serum samples..."
fastqc -o 05_rna_quality_control/fastqc_before/Serum/ \
       00_raw_data/rna_illumina/RNA-Seq_Serum/raw/*.fastq.gz

echo "FastQC before trimming complete!"
echo ""
echo "Summary of samples processed:"
ls -lh 05_rna_quality_control/fastqc_before/BHI/*.html | wc -l
echo "BHI samples"
ls -lh 05_rna_quality_control/fastqc_before/Serum/*.html | wc -l
echo "Serum samples"
