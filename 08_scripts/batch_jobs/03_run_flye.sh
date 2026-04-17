#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 8
#SBATCH -t 06:00:00
#SBATCH -J flye_assembly
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/flye_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/flye_%j.err

# Load required modules
module load Flye/2.9.6-GCC-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directory
mkdir -p 02_assembly/flye_assembly

# Run Flye assembler with PacBio reads
flye --pacbio-raw 00_raw_data/dna_pacbio/*.subreads.fastq.gz \
     --out-dir 02_assembly/flye_assembly \
     --genome-size 2.8m \
     --threads 8
