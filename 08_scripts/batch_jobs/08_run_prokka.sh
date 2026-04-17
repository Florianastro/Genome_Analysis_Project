#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 2
#SBATCH -t 00:30:00
#SBATCH -J prokka
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/03_annotation/prokka_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/03_annotation/prokka_%j.err

# Load required modules
module load prokka/1.14.5-gompi-2024a

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directory
mkdir -p 03_annotation/prokka

# Run Prokka for structural annotation
prokka --outdir 03_annotation/prokka \
       --prefix efaecium_E745 \
       --genus Enterococcus \
       --species faecium \
       --strain E745 \
       --cpus 2 \
       --force \
       02_assembly/polishing/efaecium_E745_polished.fasta
