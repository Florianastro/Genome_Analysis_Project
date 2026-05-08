#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 01:00:00
#SBATCH -J deseq2
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/06_rna_seq/deseq2_results/deseq2_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/06_rna_seq/deseq2_results/deseq2_%j.err

# Load required modules
module load R/4.5.1-gfbf-2024a
module load R-bundle-Bioconductor/3.20-foss-2024a-R-4.4.2

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  DESeq2 Differential Expression Analysis"
echo "============================================"

# Run R script
Rscript 08_scripts/R_scripts/deseq2.R

echo "============================================"
echo "  Analysis Complete!"
echo "============================================"
