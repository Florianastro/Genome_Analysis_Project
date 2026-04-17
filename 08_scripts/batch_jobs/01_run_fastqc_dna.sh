#!/bin/bash -l
#SBATCH -A uppmax2026-1-94
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -t 00:20:00
#SBATCH -J fastqc_dna
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/01_dna_quality_control/fastqc_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/01_dna_quality_control/fastqc_%j.err

# Load required modules
module load FastQC/0.12.1-Java-17

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directories
mkdir -p 01_dna_quality_control/fastqc_pacbio
mkdir -p 01_dna_quality_control/fastqc_nanopore
mkdir -p 01_dna_quality_control/fastqc_illumina

# Run FastQC on PacBio subreads
fastqc -o 01_dna_quality_control/fastqc_pacbio/ 00_raw_data/dna_pacbio/*.subreads.fastq.gz

# Run FastQC on Nanopore reads
fastqc -o 01_dna_quality_control/fastqc_nanopore/ 00_raw_data/dna_nanopore/E745_all.fasta.gz

# Run FastQC on Illumina DNA reads (for polishing)
fastqc -o 01_dna_quality_control/fastqc_illumina/ 00_raw_data/dna_illumina/*_clean.fq.gz
