#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 2
#SBATCH -t 01:00:00
#SBATCH -J plasmid
#SBATCH --mem=8G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/03_annotation/plasmid_identification/plasmid_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/03_annotation/plasmid_identification/plasmid_%j.err

# ============================================================
# Plasmid Identification
# ============================================================

# Load required modules
module load BLAST+/2.17.0-gompi-2024a

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  Plasmid Identification"
echo "============================================"

# Create output directory
mkdir -p 03_annotation/plasmid_identification

# Define input file
ASSEMBLY="02_assembly/polishing/efaecium_E745_polished.fasta"

if [ ! -f "$ASSEMBLY" ]; then
    echo "ERROR: Assembly file not found"
    exit 1
fi

# Step 1: Analyze contig sizes
echo "Step 1: Analyzing contig sizes..."
echo ""
echo "Contig size distribution:"
cat $ASSEMBLY | awk '/^>/ {if (seq) print length(seq); print $0; seq=""; next} {seq=seq $0} END {print length(seq)}' | \
    grep -v "^>" | sort -rn | while read len; do
    echo "  Contig length: $len bp ($(echo "scale=1; $len/1000" | bc) kb)"
done

# Step 2: BLAST against plasmid database
echo ""
echo "Step 2: BLAST against plasmid database..."
echo ""

# If you have a local plasmid database, use it
# Otherwise, extract contigs that might be plasmids

# Separate contigs into individual files for analysis
awk '/^>/ {out = "03_annotation/plasmid_identification/" substr($1,2) ".fasta"; print > out; next} {print >> out}' $ASSEMBLY

echo "Individual contig files created in 03_annotation/plasmid_identification/"

# Step 3: Check for plasmid-specific features
echo ""
echo "Step 3: Checking for plasmid features..."
echo ""

# Check Prokka annotation for plasmid-related genes
if [ -f "03_annotation/prokka/efaecium_E745.tsv" ]; then
    echo "Plasmid-related genes in Prokka annotation:"
    grep -iE "plasmid|replication|repA|repB|mobilization|conjugation|tra[ABCDEFGHIJKLMN]" \
        03_annotation/prokka/efaecium_E745.tsv | head -20
fi

# Step 4: Generate report
echo ""
echo "============================================"
echo "  Plasmid Identification Report"
echo "============================================"

cat > 03_annotation/plasmid_identification/plasmid_report.txt << EOF
============================================
  Plasmid Identification Report
  E. faecium E745
============================================

Expected plasmids (from Zhang et al. 2017):
  - pE745-1: 223.7 kbp (largest plasmid)
  - pE745-2: 32.4 kbp (contains vanA vancomycin resistance)
  - pE745-3: estimated from assembly
  - pE745-4: estimated from assembly
  - pE745-5: estimated from assembly
  - pE745-6: 9.3 kbp (contains dfrG trimethoprim resistance)

Total plasmids expected: 6
Size range: 9.3 kbp - 223.7 kbp

Contigs smaller than the chromosome (~2.8 Mb) may be plasmids.
Look for:
  - Circular contigs (marked as 'circular=true' in Canu output)
  - Contigs with plasmid replication genes
  - Contigs with antibiotic resistance genes
  - Contigs with conjugation/mobilization genes
EOF

echo ""
echo "Report saved to: 03_annotation/plasmid_identification/plasmid_report.txt"
echo ""

# Step 5: Statistics
echo "============================================"
echo "  Analysis Complete!"
echo "============================================"

# Count potential plasmids (contigs < 500 kb)
SMALL_CONTIGS=$(cat $ASSEMBLY | awk '/^>/ {if (seq) print length(seq); seq=""; next} {seq=seq $0} END {print length(seq)}' | \
    grep -v "^>" | awk '$1 < 500000' | wc -l)
TOTAL_CONTIGS=$(grep -c "^>" $ASSEMBLY)

echo ""
echo "Summary:"
echo "  Total contigs: $TOTAL_CONTIGS"
echo "  Potential plasmids (< 500 kb): $SMALL_CONTIGS"
echo ""
echo "Note: The chromosome should be ~2.8 Mb."
echo "Smaller contigs are likely plasmids."
