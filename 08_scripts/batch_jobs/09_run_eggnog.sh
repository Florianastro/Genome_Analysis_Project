#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 4
#SBATCH -t 14:00:00
#SBATCH -J eggnog
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/03_annotation/eggnog_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/03_annotation/eggnog_%j.err

# Load required modules
module load eggnog-mapper/2.1.13-gfbf-2024a

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directory
mkdir -p 03_annotation/eggnog

# Run eggNOG-mapper for functional annotation
emapper.py -i 03_annotation/prokka/efaecium_E745.faa \
           --output 03_annotation/eggnog/efaecium_E745 \
           --cpu 4
