#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -p pelle
#SBATCH -n 2
#SBATCH -t 02:00:00
#SBATCH -J pilon
#SBATCH --mem=32G
#SBATCH --output=/home/qich5654/Genome_Analysis_Project/02_assembly/polishing/pilon_%j.out
#SBATCH --error=/home/qich5654/Genome_Analysis_Project/02_assembly/polishing/pilon_%j.err

# Load required modules
module load Pilon/1.24-Java-17

# Change to project root directory
PROJECT_ROOT="/home/qich5654/Genome_Analysis_Project"
cd $PROJECT_ROOT

# Check environment
echo "EBROOTPILON: $EBROOTPILON"
PILON_JAR="$EBROOTPILON/pilon-1.24.jar"

# Run Pilon to polish the assembly
java -Xmx28G -jar $PILON_JAR \
    --genome 02_assembly/canu_assembly/efaecium_E745_canu.contigs.fasta \
    --frags 02_assembly/polishing/aligned.bam \
    --output efaecium_E745_polished \
    --outdir 02_assembly/polishing/ \
    --changes
