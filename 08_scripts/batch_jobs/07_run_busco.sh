#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -J busco
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/evaluation/busco_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/evaluation/busco_%j.err

# Load required modules
module load BUSCO/5.8.2-gfbf-2024a

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directory
mkdir -p 02_assembly/evaluation/busco

# Run BUSCO to assess genome completeness
busco -i 02_assembly/polishing/efaecium_E745_polished.fasta \
      -o busco_eval \
      -l lactobacillales_odb10 \
      -m genome \
      -c 4 \
      --out_path 02_assembly/evaluation/busco
