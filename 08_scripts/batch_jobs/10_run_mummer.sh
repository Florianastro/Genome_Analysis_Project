#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 01:00:00
#SBATCH -J 10_mummer
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/04_synteny/mummer_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/04_synteny/mummer_%j.err

# Load required modules
module load MUMmer/4.0.1-GCCcore-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  MUMmer Synteny Analysis Pipeline"
echo "  E. faecium E745 vs Reference Genome"
echo "============================================"
echo ""

# ============================================
# STEP 1: Download Reference Genome
# ============================================

# Define nobackup directory for storing reference
NOBACKUP_DIR="/proj/uppmax2026-1-61/nobackup/work/qich5654"
REFERENCE_DIR="${NOBACKUP_DIR}/reference_genome"
mkdir -p $REFERENCE_DIR

# Define reference file path
REFERENCE="${REFERENCE_DIR}/reference_aus0004.fasta"

# Check if reference already exists
if [ -f "$REFERENCE" ]; then
    echo "Reference genome already exists: $REFERENCE"
    echo "Skipping download step."
else
    echo "Downloading E. faecium Aus0004 reference genome..."
    echo "This is a clade A-1 strain closely related to E745."
    echo ""
    
    cd $REFERENCE_DIR
    
    # Download reference genome
    wget -q https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/250/945/GCF_000250945.1_ASM25094v1/GCF_000250945.1_ASM25094v1_genomic.fna.gz
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to download reference genome"
        echo "Trying alternative download method..."
        wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/250/945/GCF_000250945.1_ASM25094v1/GCF_000250945.1_ASM25094v1_genomic.fna.gz
    fi
    
    echo "Decompressing reference genome..."
    gunzip -f GCF_000250945.1_ASM25094v1_genomic.fna.gz
    
    echo "Renaming reference file..."
    mv GCF_000250945.1_ASM25094v1_genomic.fna reference_aus0004.fasta
    
    # Optional: Download annotation
    echo "Downloading annotation file..."
    wget -q https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/250/945/GCF_000250945.1_ASM25094v1/GCF_000250945.1_ASM25094v1_genomic.gff.gz
    
    if [ $? -eq 0 ]; then
        gunzip -f GCF_000250945.1_ASM25094v1_genomic.gff.gz
        mv GCF_000250945.1_ASM25094v1_genomic.gff reference_aus0004.gff
    fi
    
    echo "Reference genome download complete!"
    echo ""
fi

# Go back to project root
cd $PROJECT_ROOT

# Create synteny output directory
mkdir -p 04_synteny

# Create symbolic link for easy access
if [ ! -L "04_synteny/reference_aus0004.fasta" ]; then
    ln -sf $REFERENCE 04_synteny/reference_aus0004.fasta
    echo "Created symbolic link: 04_synteny/reference_aus0004.fasta -> $REFERENCE"
fi

# ============================================
# STEP 2: Verify Input Files
# ============================================

echo "============================================"
echo "  Verifying Input Files"
echo "============================================"

# Check reference genome
if [ ! -f "$REFERENCE" ]; then
    echo "ERROR: Reference genome not found at $REFERENCE"
    exit 1
fi

echo "Reference genome: $REFERENCE"
REF_CONTIGS=$(grep -c "^>" $REFERENCE)
REF_SIZE=$(cat $REFERENCE | grep -v "^>" | tr -d '\n' | wc -c)
echo "  Contigs: $REF_CONTIGS"
echo "  Total size: $REF_SIZE bases (~$(($REF_SIZE/1000000)) Mb)"

# Define query assembly
QUERY="02_assembly/polishing/efaecium_E745_polished.fasta"

if [ ! -f "$QUERY" ]; then
    echo "ERROR: Query assembly not found at $QUERY"
    echo "Please run 05_run_pilon.sh first."
    exit 1
fi

echo ""
echo "Query assembly: $QUERY"
QUERY_CONTIGS=$(grep -c "^>" $QUERY)
QUERY_SIZE=$(cat $QUERY | grep -v "^>" | tr -d '\n' | wc -c)
echo "  Contigs: $QUERY_CONTIGS"
echo "  Total size: $QUERY_SIZE bases (~$(($QUERY_SIZE/1000000)) Mb)"
echo ""

# ============================================
# STEP 3: Run MUMmer Analysis
# ============================================

echo "============================================"
echo "  Running MUMmer Analysis"
echo "============================================"

# Define output prefix
PREFIX="04_synteny/efaecium_vs_aus0004"

# Step 3a: nucmer alignment
echo "Step 1/4: Running nucmer alignment..."
nucmer --prefix=$PREFIX \
       --threads=4 \
       $REFERENCE \
       $QUERY

if [ $? -ne 0 ]; then
    echo "ERROR: nucmer alignment failed"
    exit 1
fi
echo "  nucmer alignment complete!"
echo "  Output: ${PREFIX}.delta"
echo ""

# Step 3b: Filter alignment
echo "Step 2/4: Filtering alignments..."
delta-filter -q -r \
             ${PREFIX}.delta > ${PREFIX}.filtered.delta

if [ $? -ne 0 ]; then
    echo "WARNING: delta-filter had issues, using unfiltered delta"
    cp ${PREFIX}.delta ${PREFIX}.filtered.delta
fi
echo "  Filtering complete!"
echo "  Output: ${PREFIX}.filtered.delta"
echo ""

# Step 3c: Generate statistics
echo "Step 3/4: Generating alignment statistics..."
show-coords -r -c -l ${PREFIX}.filtered.delta > ${PREFIX}.coords

if [ $? -eq 0 ]; then
    echo "  Statistics complete!"
    echo "  Output: ${PREFIX}.coords"
    
    # Display summary
    echo ""
    echo "  Coverage summary:"
    head -5 ${PREFIX}.coords
else
    echo "  WARNING: Could not generate coordinates file"
fi
echo ""

# Step 3d: Generate dot plot
echo "Step 4/4: Generating dot plot..."
mummerplot --png \
           --prefix=$PREFIX \
           --layout \
           --small \
           --filter \
           ${PREFIX}.filtered.delta

if [ $? -eq 0 ]; then
    echo "  Dot plot generated successfully!"
    echo "  Output: ${PREFIX}.png"
else
    echo "  WARNING: mummerplot had issues, trying alternative layout..."
    mummerplot --png \
               --prefix=${PREFIX}_alt \
               --layout \
               --filter \
               ${PREFIX}.filtered.delta
fi
echo ""

# ============================================
# STEP 4: Summary
# ============================================

echo "============================================"
echo "  MUMmer Analysis Complete!"
echo "============================================"
echo ""
echo "Output files in 04_synteny/:"
ls -lh 04_synteny/efaecium_vs_aus0004.* 2>/dev/null
echo ""
echo "Key output files:"
echo "  - ${PREFIX}.delta          : Raw alignment data"
echo "  - ${PREFIX}.filtered.delta : Filtered alignments"
echo "  - ${PREFIX}.coords         : Alignment coordinates"
echo "  - ${PREFIX}.png            : Dot plot visualization"
echo ""
echo "To view the dot plot, download ${PREFIX}.png to your local computer."
echo ""
echo "Quick statistics:"
echo "  Reference: E. faecium Aus0004 (${REF_CONTIGS} contigs, ${REF_SIZE} bp)"
echo "  Query:     E. faecium E745 (${QUERY_CONTIGS} contigs, ${QUERY_SIZE} bp)"
echo ""
echo "============================================"
echo "  Pipeline Finished Successfully!"
echo "============================================"
