# Genome Analysis Lab - Project Plan

## Re-analysis of *Enterococcus faecium* Fitness Determinants in Human Serum

**Based on:** Zhang et al. (2017) *BMC Genomics*, 18:893  
**Student:** Qinglongxi Chen  
**Date:** April 10, 2026  
**Course:** Genome Analysis Labs, Uppsala University

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Project Goals](#project-goals)
3. [Sample and Data Description](#sample-and-data-description)
4. [Analysis Workflow and Software](#analysis-workflow-and-software)
5. [Directory Structure](#directory-structure)
6. [File Naming Conventions](#file-naming-conventions)
7. [Time Frame and Milestones](#time-frame-and-milestones)
8. [Data Management Plan](#data-management-plan)
9. [Long-running Jobs and Optimization](#long-running-jobs-and-optimization)
10. [Biological Questions](#biological-questions)
11. [Risk Assessment](#risk-assessment)
12. [Daily Log Template](#daily-log-template)
13. [References](#references)
14. [Appendix](#appendix)

---

## Project Overview

This project aims to reproduce and extend the bioinformatics analyses from Zhang et al. (2017), which identified genes contributing to the growth and survival of vancomycin-resistant *Enterococcus faecium* in human serum. Using publicly available sequencing data, we will perform genome assembly, structural and functional annotation, and differential expression analysis to validate the authors' findings and explore additional biological questions.

| Item | Description |
|------|-------------|
| Paper | Zhang et al. (2017) *BMC Genomics*, 18:893 |
| Organism | *Enterococcus faecium* E745 (Gram-positive bacterium) |
| Data source | NCBI SRA (PRJEB19025) + course directory |

---

## Project Goals

### Basic Goals (Grade 3 Level)

- Assemble the *E. faecium* E745 genome using PacBio long reads (Canu assembler)
- Evaluate assembly quality (QUAST, BUSCO)
- Perform structural and functional annotation (Prokka, eggNOG-mapper)
- Conduct synteny comparison with a closely related *E. faecium* genome
- Preprocess Illumina RNA-seq reads (QC → trimming → QC)
- Map RNA-seq reads to the assembled genome (BWA)
- Perform differential expression analysis between BHI and heat-inactivated human serum (DESeq2)

### Extended Goals (Grade 4/5 Level)

- Compare assembly results using alternative assembler (Flye)
- Identify plasmids from the assembly
- Predict antibiotic resistance genes (ResFinder / ABRicate)
- Re-analyze Tn-seq data to identify genes essential for growth in serum
- Perform functional enrichment analysis of differentially expressed genes

---

## Sample and Data Description

### Biological Sample

| Property | Description |
|----------|-------------|
| Organism | *Enterococcus faecium* E745 |
| Source | Clinical isolate, hospitalized patient (VRE outbreak, Dutch hospital, 2000) |
| Clade | A-1 (hospital-adapted, multidrug-resistant lineage) |

### Genome Sequencing Data (DNA)

| Technology | Read type | Purpose | Trimming needed |
|------------|-----------|---------|-----------------|
| PacBio RS II | Long reads (15-20 kb) | Primary assembly | No (QC only) |
| Illumina HiSeq 2500 | 100 bp paired-end | Polishing | Yes |
| Oxford Nanopore MiniION | Long reads | Gap closure | No (QC only) |

### Transcriptomics Data (RNA)

| Condition | Phase | Replicates | Platform | Trimming needed |
|-----------|-------|------------|----------|-----------------|
| Rich medium (BHI) | Exponential | 3 | Illumina HiSeq 2500, 100 bp PE | Yes (QC → Trim → QC) |
| Heat-inactivated human serum | Exponential | 3 | Illumina HiSeq 2500, 100 bp PE | Yes (QC → Trim → QC) |

### Tn-seq Data (Optional Extra)

- Transposon mutant libraries grown in BHI vs. native/heat-inactivated human serum
- 10 replicate libraries sequenced on Illumina
- Trimming needed: Yes

---

## Analysis Workflow and Software

### Pipeline Overview

**Phase 1: DNA Quality Control**

| Step | Analysis | Data Type | Data Source | Software | Estimated Time |
|------|----------|-----------|-------------|----------|----------------|
| 1 | Quality Control (DNA) | PacBio, Nanopore | Raw long reads | FastQC | ~10 min |

**Phase 2: Genome Assembly and Annotation**

| Step | Analysis | Data Type | Data Source | Software | Estimated Time |
|------|----------|-----------|-------------|----------|----------------|
| 2 | Genome Assembly (primary) | PacBio | DNA long reads | Canu | ~2.5 h |
| 3 | Genome Assembly (optional) | PacBio | DNA long reads | Flye | ~5 h |
| 4 | Assembly Polishing | Illumina PE | DNA short reads | Pilon | ~2 h |
| 5 | Assembly Evaluation | Assembly | FASTA file | QUAST, BUSCO | <15 min |
| 6 | Structural Annotation | Assembly | FASTA file | Prokka | <5 min |
| 7 | Functional Annotation(Extra) | Proteins | FASTA file | eggNOG-mapper | ~13 h |
| 8 | Synteny Comparison(Extra) | Assembly | FASTA file | MUMmerplot | <5 min |

**Phase 3: RNA Data Preprocessing (QC → Trimming → QC)**

| Step | Analysis | Data Type | Data Source | Software | Estimated Time |
|------|----------|-----------|-------------|----------|----------------|
| 9 | Quality Control (RNA - before) | Illumina PE | Raw RNA reads | FastQC | ~10 min/sample |
| 10 | Read Trimming (RNA) | Illumina PE | RNA reads | Trimmomatic | ~50 min/sample |
| 11 | Quality Control (RNA - after) | Illumina PE | Trimmed RNA reads | FastQC | ~10 min/sample |

**Phase 4: RNA-seq Analysis**

| Step | Analysis | Data Type | Data Source | Software | Estimated Time |
|------|----------|-----------|-------------|----------|----------------|
| 12 | RNA-seq Alignment | Illumina PE | Trimmed RNA reads | BWA | ~30 min |
| 13 | Read Counting | BAM files | Alignment files | htseq-count | ~10 min |
| 14 | Differential Expression | Count matrix | Count table | DESeq2 | ~5 min |

**Phase 5: Extra Analyses (Optional)**

| Step | Analysis | Data Type | Data Source | Software | Estimated Time |
|------|----------|-----------|-------------|----------|----------------|
| 15 | Tn-seq Analysis(Extra) | Illumina | Tn-seq reads | Custom scripts | ~90 min |
| 16 | Resistance Gene Prediction(Extra) | Assembly | FASTA file | ABRicate / ResFinder | <5 min |

---

## Directory Structure

```
/proj/uppmax2026-1-61/nobackup/work/<username>/Genome_Analysis_Project/
│
├── 00_raw_data/                      # Symbolic links to raw data
│   ├── dna_pacbio/                   # PacBio long reads (no trimming needed)
│   ├── dna_nanopore/                 # Nanopore long reads (no trimming needed)
│   ├── dna_illumina/                 # Illumina short reads (for polishing)
│   ├── rna_illumina/                 # RNA-seq Illumina reads
│   └── tn_seq/                       # Tn-seq Illumina reads (extra)
│
├── 01_dna_quality_control/           # DNA read quality control (PacBio, Nanopore)
│   ├── fastqc_pacbio/
│   ├── fastqc_nanopore/
│   └── fastqc_illumina_polishing/
│
├── 02_assembly/                      # Genome assembly
│   ├── canu_assembly/                # Primary assembler (required)
│   │   ├── assembly/
│   │   └── evaluation/
│   ├── flye_assembly/                # Optional assembler (for comparison)
│   │   ├── assembly/
│   │   └── evaluation/
│   ├── polishing/                    # Pilon polishing with Illumina reads
│   └── assembly_evaluation/          # QUAST, BUSCO results
│
├── 03_annotation/                    # Genome annotation
│   ├── prokka/                       # Structural annotation
│   ├── eggnog/                       # Functional annotation
│   └── resistance_genes/             # Antibiotic resistance gene prediction
│
├── 04_synteny/                       # Comparative genomics
│   └── mummerplot/                   # Synteny plots
│
├── 05_rna_quality_control/           # RNA read quality control
│   ├── fastqc_before/                # Before trimming
│   ├── trimming_logs/                # Trimmomatic logs
│   └── fastqc_after/                 # After trimming
│
├── 06_rna_seq/                       # RNA-seq analysis
│   ├── trimmed_reads/                # Trimmed RNA reads
│   ├── alignment/                    # BWA alignment BAM files
│   ├── counts/                       # htseq-count output
│   └── deseq2_results/               # Differential expression results
│
├── 07_tn_seq/                        # Tn-seq analysis (extra)
│   ├── trimmed_reads/                # Trimmed Tn-seq reads
│   ├── mapped_reads/                 # Mapped reads
│   └── essential_genes/              # Conditionally essential genes
│
├── 08_scripts/                       # All scripts and batch jobs
│   ├── batch_jobs/                   # SLURM submission scripts
│   ├── bash_scripts/                 # Bash pipelines
│   └── R_scripts/                    # R scripts for DESeq2
│
├── 09_results_figures/               # Final results
│   ├── figures/
│   └── tables/
│
└── README.md                         # This file
```

---

## File Naming Conventions

### Naming Template

```
<project>_<sample>_<analysis>_<tool>_<condition>_<date>.<extension>
```

### Field Definitions

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| project | Project/species abbreviation | Yes | `efaecium` |
| sample | Strain/sample ID | Yes | `E745` |
| analysis | Type of analysis | Yes | `assembly`, `annotation`, `alignment`, `qc`, `trimming`, `counts`, `deseq2` |
| tool | Software used | Yes | `canu`, `flye`, `prokka`, `bwa`, `fastqc`, `trimmomatic`, `htseq` |
| condition | Experimental condition (if applicable) | No | `BHI`, `serum`, `pacbio`, `nanopore` |
| date | Run date (YYYYMMDD) | Yes | `20260408` |
| extension | File extension | Yes | `.fasta`, `.gff`, `.bam`, `.html`, `.log`, `.csv` |

### Examples

| File Type | Example |
|-----------|---------|
| DNA QC (PacBio) | `efaecium_E745_qc_fastqc_pacbio_20260408.html` |
| DNA QC (Nanopore) | `efaecium_E745_qc_fastqc_nanopore_20260408.html` |
| RNA QC (before trimming) | `efaecium_E745_qc_fastqc_BHI_before_20260408.html` |
| RNA QC (after trimming) | `efaecium_E745_qc_fastqc_BHI_after_20260408.html` |
| Trimming log | `efaecium_E745_trimming_trimmomatic_BHI_20260408.log` |
| Assembly (Canu - primary) | `efaecium_E745_assembly_canu_20260408.fasta` |
| Assembly (Flye - optional) | `efaecium_E745_assembly_flye_20260408.fasta` |
| Polished assembly | `efaecium_E745_assembly_pilon_20260408.fasta` |
| Assembly evaluation (QUAST) | `efaecium_E745_evaluation_quast_20260408/` |
| Assembly evaluation (BUSCO) | `efaecium_E745_evaluation_busco_20260408/` |
| Structural annotation | `efaecium_E745_annotation_prokka_20260408.gff` |
| Functional annotation | `efaecium_E745_annotation_eggnog_20260408.tsv` |
| Synteny plot | `efaecium_E745_synteny_mummer_20260408.png` |
| RNA-seq alignment (BHI) | `efaecium_E745_alignment_bwa_BHI_20260408.bam` |
| RNA-seq alignment (serum) | `efaecium_E745_alignment_bwa_serum_20260408.bam` |
| Count matrix | `efaecium_E745_counts_htseq_20260408.txt` |
| DE results | `efaecium_E745_deseq2_serum_vs_BHI_20260408.csv` |
| Resistance genes | `efaecium_E745_resistance_abricate_20260408.txt` |
| Batch script | `run_canu_assembly_20260408.sh` |

### Rules

- Use **lowercase letters** only
- Use **underscores `_`** to separate fields
- Use **hyphens `-`** to separate versions or parameters (if needed)
- Use **date format `YYYYMMDD`** (e.g., `20260408` for April 8, 2026)
- **Optional fields** (like `condition`) can be omitted if not applicable
- **Avoid** spaces, `/`, `\`, `()`, `*`, `?`, and other special characters

---

## Time Frame and Milestones

| Week/Date | Activity | Deliverable |
|-----------|----------|-------------|
| Apr 8 | GitHub seminar | Repository created |
| **Apr 10** | **Project plan deadline** | **This document in wiki** |
| Apr 15 | Lab session | DNA QC + Canu assembly started |
| Apr 16 | Compulsory assembly | Canu assembly + evaluation completed |
| Apr 21 | Lab session | Polishing + annotation started |
| Apr 24 | Lab session | Flye assembly (optional) + Synteny |
| Apr 28 | Compulsory annotation | Annotation completed |
| May 5 | Lab session | RNA QC + trimming |
| May 8 | Lab session | RNA-seq alignment + counting |
| May 11 | Compulsory DE | DE results ready |
| May 19 | Compulsory wiki | Wiki fully documented |
| **May 22** | **GitHub final upload** | **All code + results in repo** |
| **May 26** | **Presentations** | **10 min + 5 min discussion** |

### UPPMAX Reservation Codes

| Date | Reservation Code |
|------|------------------|
| Apr 15 | uppmax2026-1-61_1 |
| Apr 16 | uppmax2026-1-61_2 |
| Apr 21 | uppmax2026-1-61_3 |
| Apr 24 | uppmax2026-1-61_4 |
| Apr 28 | uppmax2026-1-61_5 |
| May 5 | uppmax2026-1-61_6 |
| May 8 | uppmax2026-1-61_7 |
| May 11 | uppmax2026-1-61_8 |
| May 19 | uppmax2026-1-61_9 |
| May 22 | uppmax2026-1-61_10 |

---

## Data Management Plan

### Storage Locations

| Location | Capacity | Content |
|----------|----------|---------|
| Project nobackup | Large (shared) | Large intermediate files (BAM, assembly) |
| Home directory | 32 GB (private) | Scripts, config files, small results |
| GitHub | Unlimited | Code, wiki documentation |

### Key Principles

- **No copying of raw data:** Use symbolic links (`ln -s`)
- **DNA long reads (PacBio/Nanopore):** QC only, no trimming required
- **RNA reads:** QC → Trimming → QC (performed after genome annotation is complete)
- **Compressed storage:** Convert SAM → BAM; keep FASTQ files compressed (.gz)
- **Informative naming:** Follow naming convention above
- **Documentation:** All commands recorded in GitHub wiki daily log
- **Version control:** All scripts stored in GitHub repository

### Symbolic Links for Raw Data

```bash
# In 00_raw_data/ directory
cd ~/Genome_Analysis_Project/00_raw_data/

# Link DNA PacBio data
ln -s /proj/uppmax2026-1-61/Genome_Analysis/Paper_I/PacBio/*.fastq.gz dna_pacbio/

# Link DNA Nanopore data
ln -s /proj/uppmax2026-1-61/Genome_Analysis/Paper_I/Nanopore/*.fastq.gz dna_nanopore/

# Link DNA Illumina data (for polishing)
ln -s /proj/uppmax2026-1-61/Genome_Analysis/Paper_I/Illumina_DNA/*.fastq.gz dna_illumina/

# Link RNA-seq data
ln -s /proj/uppmax2026-1-61/Genome_Analysis/Paper_I/RNA_seq/*.fastq.gz rna_illumina/

# Link Tn-seq data (optional)
ln -s /proj/uppmax2026-1-61/Genome_Analysis/Paper_I/Tn_seq/*.fastq.gz tn_seq/
```

### Space Monitoring

```bash
# Check available space in home directory
uquota -u <username>

# Check project directory usage
du -sh /proj/uppmax2026-1-61/nobackup/work/<username>/
```

---

## Long-running Jobs and Optimization

### Batch Job Template

```bash
#!/bin/bash -l
#SBATCH -A uppmax2026-1-61
#SBATCH -M snowy
#SBATCH -n 2
#SBATCH -t 12:00:00
#SBATCH -J job_name
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x.%j.out
#SBATCH --error=logs/%x.%j.err

# Load modules
module load <module_name>

# Run command
<command>
```

### Long-running Analyses

| Analysis | Estimated Time | Strategy |
|----------|---------------|----------|
| Canu assembly | ~2.5 h | Submit as batch job or run during reservation |
| Flye assembly (optional) | ~5 h | Submit as batch job |
| eggNOG-mapper | ~13 h | Submit as batch job, run overnight |
| RNA trimming (6 samples) | ~50 min each | Submit as array job |
| RNA-seq alignment (6 samples) | ~30 min each | Submit as array job |
| Tn-seq analysis | ~90 min | Run as batch job |

### Job Monitoring Commands

```bash
# Check job status
squeue -M snowy -u <username>

# Check job details after completion
sacct -j <JOBID> --format=JobID,JobName,AllocCPUS,State,MaxRSS,Elapsed

# Cancel a job
scancel <JOBID> -M snowy
```

---

## Biological Questions

1. Which *E. faecium* genes are significantly upregulated in human serum compared to rich medium?
2. Do our RNA-seq results confirm the authors' finding that purine biosynthesis genes (*purD*, *purH*, *purL*) are induced in serum?
3. Can we independently identify the same set of conditionally essential genes from Tn-seq data (e.g., *pyrK_2*, *pyrF*, *manY_2*)?
4. What is the role of carbohydrate metabolism genes (e.g., *manY_2*, *ptsL*) in serum survival?
5. Are there antibiotic resistance genes on plasmids that correlate with clinical isolates?
6. Does the prophage region (highly expressed in serum) contain any known virulence factors?

---

## Risk Assessment

| Potential Issue | Mitigation |
|----------------|------------|
| Assembly fails or is highly fragmented | Use Canu as primary; try Flye as alternative |
| Long running time for eggNOG-mapper | Start early, use batch job, monitor with squeue |
| Misunderstanding of Tn-seq data | Focus on RNA-seq as primary; Tn-seq as extra |
| Disk space full in home directory | Use project nobackup folder; delete intermediate files |
| GitHub push fails | Use `git pull` first, check PAT/SSH keys |
| Module not found on UPPMAX | Use `module spider` to find correct module name |
| Memory limit exceeded in job | Increase `--mem` parameter in SLURM script |
| Results don't match paper | Document differences; discuss possible causes in wiki |

---

## Daily Log Template

The GitHub wiki will contain a daily log with the following structure:

```markdown
## Date: YYYY-MM-DD

### Tasks Completed
- [ ] Task 1
- [ ] Task 2

### Commands Run
```
command_1
command_2
```

### Input/Output Files
- Input: /path/to/input.file
- Output: /path/to/output.file

### Problems Encountered
- Problem description

### Solutions / Next Steps
- Solution or planned approach

### Time Spent
- X hours
```

---

## References

1. Zhang X, de Maat V, Guzman Prieto AM, et al. (2017) RNA-seq and Tn-seq reveal fitness determinants of vancomycin-resistant *Enterococcus faecium* during growth in human serum. *BMC Genomics*, 18:893.

2. UPPMAX Documentation. https://docs.uppmax.uu.se/

3. Genome Analysis Labs Student Manual 2026. Uppsala University.

4. GitHub Documentation. https://docs.github.com/

---

## Appendix

### UPPMAX Connection Instructions

```bash
# Connect to UPPMAX (with X11 forwarding for GUI)
ssh -AX <username>@pelle.uppmax.uu.se

# Allocate interactive node (during lab hours with reservation)
salloc -A uppmax2026-1-61 -c 2 -t 04:00:00 --reservation=<code>

# Load modules
module load <module_name>
```

### DNA Quality Control Commands (PacBio/Nanopore)

```bash
# FastQC on PacBio long reads (QC only, no trimming)
fastqc pacbio_reads.fastq.gz -o 01_dna_quality_control/fastqc_pacbio/

# FastQC on Nanopore long reads (QC only, no trimming)
fastqc nanopore_reads.fastq.gz -o 01_dna_quality_control/fastqc_nanopore/
```

### Canu Assembly Command

```bash
# Canu assembly for PacBio reads (primary assembler)
canu -p efaecium_E745 -d 02_assembly/canu_assembly/ \
    genomeSize=2.8m \
    -pacbio-raw pacbio_reads.fastq.gz \
    useGrid=false \
    maxThreads=4
```

### RNA Quality Control and Trimming Commands

```bash
# Step 1: QC before trimming
fastqc rna_sample_R1.fastq.gz -o 05_rna_quality_control/fastqc_before/
fastqc rna_sample_R2.fastq.gz -o 05_rna_quality_control/fastqc_before/

# Step 2: Trimmomatic (paired-end)
trimmomatic PE \
    rna_sample_R1.fastq.gz rna_sample_R2.fastq.gz \
    06_rna_seq/trimmed_reads/sample_R1_trimmed.fastq.gz \
    06_rna_seq/trimmed_reads/sample_R1_unpaired.fastq.gz \
    06_rna_seq/trimmed_reads/sample_R2_trimmed.fastq.gz \
    06_rna_seq/trimmed_reads/sample_R2_unpaired.fastq.gz \
    ILLUMINACLIP:adapters.fa:2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

# Step 3: QC after trimming
fastqc sample_R1_trimmed.fastq.gz -o 05_rna_quality_control/fastqc_after/
fastqc sample_R2_trimmed.fastq.gz -o 05_rna_quality_control/fastqc_after/
```

### DESeq2 Analysis Template (R)

```r
# Load DESeq2 in R
library(DESeq2)

# Read count matrix
countData <- read.table("counts_matrix.txt", header=TRUE, row.names=1)
colData <- data.frame(condition=c("BHI","BHI","BHI","serum","serum","serum"))

# Create DESeq2 object
dds <- DESeqDataSetFromMatrix(countData, colData, ~condition)

# Run DESeq2
dds <- DESeq(dds)

# Get results
res <- results(dds, contrast=c("condition","serum","BHI"))
res <- res[order(res$padj),]

# Write results
write.csv(as.data.frame(res), "deseq2_results.csv")
```

---

## License

This project is for educational purposes as part of the Genome Analysis Labs course at Uppsala University.

---

**Last updated:** April 10, 2026
