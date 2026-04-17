#!/bin/bash -l
#SBATCH -A uppmax2026-1-94
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 04:00:00
#SBATCH -J 02_canu
#SBATCH --mem=32G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/canu_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/canu_%j.err

# Load required modules
module load canu/2.3-GCCcore-13.3.0-Java-17
module load SAMtools/1.22.1-GCC-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Create output directory
mkdir -p 02_assembly/canu_assembly

# Run Canu with the single merged file
canu -p efaecium_E745_canu \
     -d 02_assembly/canu_assembly \
     genomeSize=2.8m \
     -pacbio-raw 00_raw_data/dna_pacbio/*.subreads.fastq.gz \
     useGrid=false \
     maxThreads=4
