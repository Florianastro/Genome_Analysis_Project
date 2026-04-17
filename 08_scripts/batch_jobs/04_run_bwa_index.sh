#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 2
#SBATCH -t 02:00:00
#SBATCH -J bwa_pilon
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/polishing/bwa_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/polishing/bwa_%j.err

# Load required modules
module load BWA/0.7.19-GCCcore-13.3.0
module load SAMtools/1.22.1-GCC-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directory
mkdir -p 02_assembly/polishing

# Define input files
ASSEMBLY=02_assembly/canu_assembly/efaecium_E745_canu.contigs.fasta
R1=00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_1_clean.fq.gz
R2=00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_2_clean.fq.gz

# Index the assembly
bwa index $ASSEMBLY

# Align Illumina reads to the assembly and sort
bwa mem -t 2 $ASSEMBLY $R1 $R2 | samtools sort -@2 -o 02_assembly/polishing/aligned.bam

# Index the BAM file
samtools index 02_assembly/polishing/aligned.bam
