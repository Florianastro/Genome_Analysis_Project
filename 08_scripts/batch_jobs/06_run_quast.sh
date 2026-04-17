#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -J quast
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/evaluation/quast_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/evaluation/quast_%j.err

# Load required modules
module load QUAST/5.3.0-gfbf-2024a

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directory
mkdir -p 02_assembly/evaluation/quast

# Run QUAST to evaluate assembly quality
quast.py 02_assembly/polishing/efaecium_E745_polished.fasta \
    -o 02_assembly/evaluation/quast \
    --gene-finding
