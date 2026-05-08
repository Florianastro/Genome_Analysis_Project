#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 8
#SBATCH -t 06:00:00
#SBATCH -J spades_hybrid
#SBATCH --mem=64G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/spades_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/spades_%j.err

# ============================================================
# SPAdes Hybrid Assembly
# Illumina short reads + PacBio/Nanopore long reads
# ============================================================

# Load required modules
module load SPAdes/4.2.0-GCC-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  SPAdes Hybrid Assembly"
echo "============================================"

# Create output directory
mkdir -p 02_assembly/spades_hybrid

# Define input files
ILLUMINA_R1="00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_1_clean.fq.gz"
ILLUMINA_R2="00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_2_clean.fq.gz"
PACBIO_DIR="00_raw_data/dna_pacbio"
NANOPORE_READS="00_raw_data/dna_nanopore/E745_all.fasta.gz"

echo "Input files:"
echo "  Illumina R1: $ILLUMINA_R1"
echo "  Illumina R2: $ILLUMINA_R2"
echo "  Nanopore:    $NANOPORE_READS"
echo ""

# Check input files
if [ ! -f "$ILLUMINA_R1" ] || [ ! -f "$ILLUMINA_R2" ]; then
    echo "ERROR: Illumina files not found"
    exit 1
fi
if [ ! -f "$NANOPORE_READS" ]; then
    echo "ERROR: Nanopore file not found"
    exit 1
fi

# ============================================================
# Build command with individual PacBio files
# ============================================================

echo "Building SPAdes command with PacBio files..."
PACBIO_ARGS=""
for f in $PACBIO_DIR/*.subreads.fastq.gz; do
    # Skip if it's a symlink pointing to a non-existent file
    if [ ! -f "$f" ] && [ ! -L "$f" ]; then
        continue
    fi
    PACBIO_ARGS="$PACBIO_ARGS --pacbio $f"
    echo "  Adding: $f"
done

# ============================================================
# Option A: Illumina + PacBio Hybrid
# ============================================================

echo ""
echo "============================================"
echo "  Option A: Illumina + PacBio Hybrid"
echo "============================================"

spades.py \
    -1 $ILLUMINA_R1 \
    -2 $ILLUMINA_R2 \
    $PACBIO_ARGS \
    -o 02_assembly/spades_hybrid/pacbio_hybrid \
    -t 8 \
    -m 60 \
    --isolate \
    --only-assembler

echo "Illumina + PacBio hybrid assembly complete!"

# ============================================================
# Option B: Illumina + Nanopore Hybrid
# ============================================================

echo ""
echo "============================================"
echo "  Option B: Illumina + Nanopore Hybrid"
echo "============================================"

spades.py \
    -1 $ILLUMINA_R1 \
    -2 $ILLUMINA_R2 \
    --nanopore $NANOPORE_READS \
    -o 02_assembly/spades_hybrid/nanopore_hybrid \
    -t 8 \
    -m 60 \
    --isolate \
    --only-assembler

echo "Illumina + Nanopore hybrid assembly complete!"

# ============================================================
# Generate assembly statistics
# ============================================================

echo ""
echo "============================================"
echo "  Assembly Statistics"
echo "============================================"

for assembly_dir in 02_assembly/spades_hybrid/*/; do
    ASSEMBLY_NAME=$(basename $assembly_dir)
    CONTIGS="${assembly_dir}/contigs.fasta"
    
    if [ -f "$CONTIGS" ]; then
        echo ""
        echo "Assembly: $ASSEMBLY_NAME"
        echo "------------------------"
        CONTIG_COUNT=$(grep -c "^>" $CONTIGS)
        TOTAL_BASES=$(cat $CONTIGS | grep -v "^>" | tr -d '\n' | wc -c)
        echo "  Contigs: $CONTIG_COUNT"
        echo "  Total length: $TOTAL_BASES bp (~$(($TOTAL_BASES/1000000)) Mb)"
        
        if [ $TOTAL_BASES -gt 0 ]; then
            N50=$(awk '/^>/ {if (seq) print length(seq); seq=""; next} {seq=seq $0} END {print length(seq)}' $CONTIGS | sort -rn | awk -v t=$TOTAL_BASES '{s+=$1; if (s>=t/2) {print $1; exit}}')
            echo "  N50: $N50 bp (~$(($N50/1000)) kb)"
        fi
    else
        echo ""
        echo "Assembly: $ASSEMBLY_NAME - FAILED (no contigs.fasta)"
    fi
done

echo ""
echo "============================================"
echo "  SPAdes Assembly Complete!"
echo "============================================"
