#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -t 02:00:00
#SBATCH -J merqury
#SBATCH --mem=32G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/evaluation/merqury_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/evaluation/merqury_%j.err

# ============================================================
# Merqury: Reference-free assembly evaluation
# ============================================================

# Load required modules
module load meryl/1.4.1-GCCcore-13.3.0
module load merqury/20240628-1ad7c32-gfbf-2024a

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  Merqury Assembly Evaluation"
echo "============================================"

# Create output directory
mkdir -p 02_assembly/evaluation/merqury

# Define files
ILLUMINA_R1="00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_1_clean.fq.gz"
ILLUMINA_R2="00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_2_clean.fq.gz"
ASSEMBLY="02_assembly/polishing/efaecium_E745_polished.fasta"

# Step 1: Build k-mer database from Illumina reads
echo "Step 1: Building k-mer database from Illumina reads..."
echo "  This may take ~1 hour..."

meryl count \
    k=21 \
    threads=8 \
    $ILLUMINA_R1 \
    $ILLUMINA_R2 \
    output 02_assembly/evaluation/merqury/illumina.meryl

echo ""
echo "Step 2: Running Merqury evaluation..."

# Step 2: Evaluate assembly
merqury.sh \
    02_assembly/evaluation/merqury/illumina.meryl \
    $ASSEMBLY \
    efaecium_E745

# Move output files
mv efaecium_E745.* 02_assembly/evaluation/merqury/ 2>/dev/null

echo ""
echo "============================================"
echo "  Merqury Evaluation Complete!"
echo "============================================"
echo ""

# Display results
if [ -f "02_assembly/evaluation/merqury/efaecium_E745.qv" ]; then
    echo "Assembly Quality Value (QV):"
    cat 02_assembly/evaluation/merqury/efaecium_E745.qv
    echo ""
fi

if [ -f "02_assembly/evaluation/merqury/efaecium_E745.completeness.stats" ]; then
    echo "Completeness Statistics:"
    cat 02_assembly/evaluation/merqury/efaecium_E745.completeness.stats
fi

echo ""
echo "Output files in 02_assembly/evaluation/merqury/:"
ls -lh 02_assembly/evaluation/merqury/
