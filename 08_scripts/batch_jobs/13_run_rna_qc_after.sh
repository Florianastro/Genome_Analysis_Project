#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -J rna_qc_after
#SBATCH --mem=8G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/05_rna_quality_control/fastqc_after_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/05_rna_quality_control/fastqc_after_%j.err

# Load required modules
module load FastQC/0.12.1-Java-17

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  RNA-seq Quality Control - After Trimming"
echo "============================================"

# Create output directories
mkdir -p 05_rna_quality_control/fastqc_after/BHI
mkdir -p 05_rna_quality_control/fastqc_after/Serum

# Run FastQC on trimmed BHI samples
echo "Running FastQC on trimmed BHI samples..."
fastqc -o 05_rna_quality_control/fastqc_after/BHI/ \
       06_rna_seq/trimmed_reads/BHI/*_trimmed_R*.fastq.gz

# Run FastQC on trimmed Serum samples
echo "Running FastQC on trimmed Serum samples..."
fastqc -o 05_rna_quality_control/fastqc_after/Serum/ \
       06_rna_seq/trimmed_reads/Serum/*_trimmed_R*.fastq.gz

echo "FastQC after trimming complete!"
