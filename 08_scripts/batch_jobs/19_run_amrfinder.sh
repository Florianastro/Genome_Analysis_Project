#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 01:00:00
#SBATCH -J amrfinder
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/03_annotation/resistance_genes/amrfinder_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/03_annotation/resistance_genes/amrfinder_%j.err

# ============================================================
# Antibiotic Resistance Gene Detection with AMRFinderPlus
# ============================================================

# Load required modules
module load AMRFinderPlus/4.2.7-gompi-2024a

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  AMRFinderPlus Resistance Gene Detection"
echo "============================================"

# Create output directory
mkdir -p 03_annotation/resistance_genes

# Use nobackup for AMRFinder database (same location as eggNOG)
DB_DIR="/proj/uppmax2026-1-61/nobackup/work/qich5654/amrfinder_db"

# ============================================================
# Step 1: Download database (if not exists)
# ============================================================

if [ ! -f "${DB_DIR}/latest/AMR_CDS" ]; then
    echo "Downloading AMRFinderPlus database..."
    echo "  This may take 10-30 minutes..."
    echo ""
    
    mkdir -p $DB_DIR
    cd $DB_DIR
    
    amrfinder_update -d . 2>&1 || amrfinder -u -d . 2>&1
    
    cd $PROJECT_ROOT
    echo "  Database download complete!"
else
    echo "AMRFinder database already exists."
fi

echo ""

# Define input files
ASSEMBLY="02_assembly/polishing/efaecium_E745_polished.fasta"
PROTEINS="03_annotation/prokka/efaecium_E745.faa"
GFF="03_annotation/prokka/efaecium_E745.gff"

# ============================================================
# Step 2: Run AMRFinderPlus on genome assembly
# ============================================================

echo "============================================"
echo "  Running AMRFinderPlus on genome assembly"
echo "============================================"

amrfinder \
    --nucleotide $ASSEMBLY \
    --database ${DB_DIR}/latest \
    --output 03_annotation/resistance_genes/amrfinder_genome.txt \
    --name E745_genome \
    --threads 4 \
    --plus

echo "Genome analysis complete!"
echo ""

# ============================================================
# Step 3: Run AMRFinderPlus on proteins
# ============================================================

echo "============================================"
echo "  Running AMRFinderPlus on protein sequences"
echo "============================================"

if [ -f "$PROTEINS" ]; then
    amrfinder \
        --protein $PROTEINS \
        --database ${DB_DIR}/latest \
        --output 03_annotation/resistance_genes/amrfinder_protein.txt \
        --name E745_protein \
        --threads 4 \
        --plus
    
    echo "Protein analysis complete!"
else
    echo "  Protein file not found, skipping."
fi

echo ""

# ============================================================
# Summary
# ============================================================

echo "============================================"
echo "  AMRFinderPlus Analysis Complete!"
echo "============================================"
echo ""

if [ -s "03_annotation/resistance_genes/amrfinder_genome.txt" ]; then
    echo "Detected resistance genes:"
    echo "--------------------------"
    awk -F'\t' 'NR>1 {
        gene=$7; class=$8; method=$6;
        if (gene != "") printf "  %-30s %-25s %s\n", gene, "["class"]", "("method")"
    }' 03_annotation/resistance_genes/amrfinder_genome.txt
else
    echo "  No results generated."
fi

echo ""
echo "Output files:"
ls -lh 03_annotation/resistance_genes/
