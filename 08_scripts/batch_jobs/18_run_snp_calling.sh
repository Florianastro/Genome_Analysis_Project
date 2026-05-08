#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 1
#SBATCH -c 4
#SBATCH -t 02:00:00
#SBATCH -J snp_calling
#SBATCH --mem=16G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/snp_calling/snp_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/snp_calling/snp_%j.err

# ============================================================
# SNP Calling with BCFtools
# ============================================================

# Load required modules
module load BCFtools/1.22.1-GCC-13.3.0
module load SAMtools/1.22.1-GCC-13.3.0
module load BWA/0.7.19-GCCcore-13.3.0

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

echo "============================================"
echo "  SNP Calling with BCFtools"
echo "============================================"

# Create output directories
mkdir -p 02_assembly/snp_calling
mkdir -p 02_assembly/snp_calling/tmp

# Define files
REFERENCE="02_assembly/polishing/efaecium_E745_polished.fasta"
ILLUMINA_R1="00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_1_clean.fq.gz"
ILLUMINA_R2="00_raw_data/dna_illumina/E745-1.L500_SZAXPI015146-56_2_clean.fq.gz"
TMPDIR="02_assembly/snp_calling/tmp"

# Check input files
if [ ! -f "$REFERENCE" ]; then
    echo "ERROR: Reference genome not found"
    exit 1
fi
if [ ! -f "$ILLUMINA_R1" ]; then
    echo "ERROR: Illumina R1 not found"
    exit 1
fi

echo "Reference: $(basename $REFERENCE)"
echo ""

# ============================================================
# Step 1: Prepare reference
# ============================================================

echo "Step 1: Preparing reference..."

if [ ! -f "${REFERENCE}.bwt" ]; then
    echo "  BWA indexing..."
    bwa index $REFERENCE
fi

if [ ! -f "${REFERENCE}.fai" ]; then
    echo "  SAMtools indexing..."
    samtools faidx $REFERENCE
fi

echo "  Done!"
echo ""

# ============================================================
# Step 2: BWA alignment to POLISHED assembly
# ============================================================

echo "Step 2: BWA alignment to polished assembly..."

BAM_POLISHED="02_assembly/snp_calling/aligned_to_polished.bam"

bwa mem -t 4 -M $REFERENCE $ILLUMINA_R1 $ILLUMINA_R2 2> ${TMPDIR}/bwa.log | \
    samtools view -bS -h - 2> ${TMPDIR}/view.log | \
    samtools sort -@4 -T ${TMPDIR} -o $BAM_POLISHED - 2> ${TMPDIR}/sort.log

if [ $? -ne 0 ] || [ ! -s "$BAM_POLISHED" ]; then
    echo "  ERROR: BWA alignment failed"
    exit 1
fi

samtools index $BAM_POLISHED
echo "  Done!"
echo ""

# ============================================================
# Step 3: Generate pileup + call variants
# ============================================================

echo "Step 3: Calling variants..."

# Use bcftools mpileup with -Ou (uncompressed BCF) pipe to call
bcftools mpileup -f $REFERENCE -O u $BAM_POLISHED | \
    bcftools call -c -v -O v \
    > 02_assembly/snp_calling/raw_variants.vcf 2> ${TMPDIR}/call_err.log

if [ ! -s "02_assembly/snp_calling/raw_variants.vcf" ]; then
    echo "  ERROR: Variant calling failed"
    cat ${TMPDIR}/call_err.log
    exit 1
fi

RAW_COUNT=$(grep -c -v "^#" 02_assembly/snp_calling/raw_variants.vcf 2>/dev/null || echo 0)
echo "  Raw variants called: $RAW_COUNT"
echo "  Done!"
echo ""

# ============================================================
# Step 4: Filter variants by quality
# ============================================================

echo "Step 4: Filtering variants (QUAL >= 20)..."

# Use awk to filter by QUAL (column 6 in VCF) - simpler and more reliable
grep "^#" 02_assembly/snp_calling/raw_variants.vcf > 02_assembly/snp_calling/filtered_variants.vcf
awk -F'\t' '$6 >= 20 && !/^#/' 02_assembly/snp_calling/raw_variants.vcf >> 02_assembly/snp_calling/filtered_variants.vcf

if [ ! -s "02_assembly/snp_calling/filtered_variants.vcf" ]; then
    echo "  WARNING: No variants passed QUAL >= 20 filter"
fi

FILTERED_COUNT=$(grep -c -v "^#" 02_assembly/snp_calling/filtered_variants.vcf 2>/dev/null || echo 0)
echo "  Filtered variants: $FILTERED_COUNT"
echo "  Done!"
echo ""

# ============================================================
# Step 5: Statistics
# ============================================================

echo "Step 5: Generating statistics..."

bcftools stats 02_assembly/snp_calling/filtered_variants.vcf > \
    02_assembly/snp_calling/variant_stats.txt 2>/dev/null || echo "  Stats generation skipped"

echo "  Done!"
echo ""

# ============================================================
# Summary
# ============================================================

echo "============================================"
echo "  SNP Calling Complete!"
echo "============================================"
echo ""

# Count variants by type
SNPS=$(grep -v "^#" 02_assembly/snp_calling/filtered_variants.vcf 2>/dev/null | grep -c "TYPE=snp" || echo 0)
INDELS=$(grep -v "^#" 02_assembly/snp_calling/filtered_variants.vcf 2>/dev/null | grep -c "TYPE=indel" || echo 0)
TS_TV=$(grep -v "^#" 02_assembly/snp_calling/filtered_variants.vcf 2>/dev/null | awk '{
    if ($4 ~ /^[AT]$/ && $5 ~ /^[GC]$/) ts++;
    else if ($4 ~ /^[GC]$/ && $5 ~ /^[AT]$/) ts++;
    else if ($4 ~ /^[AT]$/ && $5 ~ /^[AT]$/) tv++;
    else if ($4 ~ /^[GC]$/ && $5 ~ /^[GC]$/) tv++;
    else tv++
} END {printf "%.2f", ts/tv}' 2>/dev/null || echo "N/A")

echo "Variant Summary:"
echo "  Raw variants:       $RAW_COUNT"
echo "  Filtered (QUAL>=20): $FILTERED_COUNT"
echo "    SNPs:             $SNPS"
echo "    INDELs:           $INDELS"
if [ "$TS_TV" != "N/A" ] && [ -n "$TS_TV" ]; then
    echo "    Ts/Tv ratio:      $TS_TV"
fi
echo ""
echo "Output files:"
ls -lh 02_assembly/snp_calling/*.vcf 2>/dev/null
ls -lh 02_assembly/snp_calling/*.txt 2>/dev/null

# Clean up
rm -rf ${TMPDIR}
