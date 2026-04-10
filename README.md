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

- Assemble the *E. faecium* E745 genome using PacBio long reads
- Evaluate assembly quality (QUAST, BUSCO)
- Perform structural and functional annotation (Prokka, eggNOG-mapper)
- Conduct synteny comparison with a closely related *E. faecium* genome
- Preprocess Illumina RNA-seq reads (quality trimming + QC)
- Map RNA-seq reads to the assembled genome (BWA)
- Perform differential expression analysis between BHI and heat-inactivated human serum (DESeq2)

### Extended Goals (Grade 4/5 Level)

- Compare assembly results using different assemblers (Flye vs. Canu)
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

### Genome Sequencing Data

| Technology | Read type | Purpose |
|------------|-----------|---------|
| PacBio RS II | Long reads (15-20 kb) | Primary assembly |
| Illumina HiSeq 2500 | 100 bp paired-end | Polishing |
| Oxford Nanopore MiniION | Long reads | Gap closure |

### Transcriptomics Data (RNA-seq)

| Condition | Phase | Replicates | Platform |
|-----------|-------|------------|----------|
| Rich medium (BHI) | Exponential | 3 | Illumina HiSeq 2500, 100 bp PE |
| Heat-inactivated human serum | Exponential | 3 | Illumina HiSeq 2500, 100 bp PE |

### Tn-seq Data (Optional Extra)

- Transposon mutant libraries grown in BHI vs. native/heat-inactivated human serum
- 10 replicate libraries sequenced on Illumina

---

## Analysis Workflow and Software

### Pipeline Overview

| Step | Analysis | Software | Estimated Time |
|------|----------|----------|----------------|
| 1 | Quality Control | FastQC | ~10 min |
| 2 | Read Trimming | Trimmomatic | ~50 min/file |
| 3 | Genome Assembly | Flye / Canu | 2.5-5 h |
| 4 | Assembly Polishing | Pilon | ~2 h |
| 5 | Assembly Evaluation | QUAST, BUSCO | <15 min |
| 6 | Structural Annotation | Prokka | <5 min |
| 7 | Functional Annotation | eggNOG-mapper | ~13 h |
| 8 | Synteny Comparison | MUMmerplot | <5 min |
| 9 | RNA-seq Alignment | BWA | ~30 min |
| 10 | Read Counting | htseq-count | ~10 min |
| 11 | Differential Expression | DESeq2 | ~5 min |
| 12 | Tn-seq Analysis (extra) | Custom scripts | ~90 min |
| 13 | Resistance Gene Prediction | ABRicate / ResFinder | <5 min |

---

## Directory Structure

```
/proj/uppmax2026-1-61/nobackup/work/<username>/Genome_Analysis_Project/
│
├── 00_raw_data/              # Symbolic links to raw data
│   └── links_to_raw_data.sh
│
├── 01_quality_control/       # FastQC reports, trimming logs
│   ├── fastqc_before/
│   ├── fastqc_after/
│   └── trimming_logs/
│
├── 02_assembly/              # Genome assembly and evaluation
│   ├── flye_assembly/
│   ├── canu_assembly/        # (optional)
│   ├── polishing/
│   └── assembly_evaluation/
│
├── 03_annotation/            # Genome annotation
│   ├── prokka/
│   ├── eggnog/
│   └── resistance_genes/
│
├── 04_rna_seq/               # RNA-seq analysis
│   ├── trimmed_reads/
│   ├── alignment/
│   ├── counts/
│   └── deseq2_results/
│
├── 05_tn_seq/                # Tn-seq analysis (extra)
│   ├── mapped_reads/
│   └── essential_genes/
│
├── 06_synteny/               # Comparative genomics
│   └── mummerplot/
│
├── 07_scripts/               # All scripts and batch jobs
│   ├── batch_jobs/
│   ├── bash_scripts/
│   └── R_scripts/
│
├── 08_results_figures/       # Final results
│   ├── figures/
│   └── tables/
│
└── README.md                 # This file
```

---

## File Naming Conventions

### Naming Template

```
<project>_<sample>_<analysis>_<tool>_<YYYYMMDD>.<extension>
```

### Examples

| File Type | Example |
|-----------|---------|
| Assembly | `efaecium_E745_flye_20260408.fasta` |
| Annotation | `efaecium_E745_prokka_20260408.gff` |
| RNA-seq alignment (BHI) | `efaecium_E745_BHI_bwa_20260408.bam` |
| RNA-seq alignment (serum) | `efaecium_E745_serum_bwa_20260408.bam` |
| Count matrix | `efaecium_E745_counts_htseq_20260408.txt` |
| DE results | `efaecium_E745_deseq2_serum_vs_BHI_20260408.csv` |
| Batch script | `run_flye_assembly_20260408.sh` |

### Rules

- Use lowercase letters
- Use underscores `_` to separate words
- Use hyphens `-` to separate versions or parameters
- Use date format `YYYYMMDD`
- Avoid spaces, `/`, `\`, `()`, `*`, `?`

---

## Time Frame and Milestones

| Week/Date | Activity | Deliverable |
|-----------|----------|-------------|
| Apr 8 | GitHub seminar | Repository created |
| **Apr 10** | **Project plan deadline** | **This document in wiki** |
| Apr 15 | Lab session | Genome assembly started |
| Apr 16 | Compulsory assembly | Assembly + evaluation completed |
| Apr 21 | Lab session | Polishing + annotation started |
| Apr 28 | Compulsory annotation | Annotation completed |
| May 5 | Lab session | RNA-seq mapping + counting |
| May 8 | Lab session | Differential expression analysis |
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
- **Compressed storage:** Convert SAM → BAM; keep FASTQ files compressed (.gz)
- **Informative naming:** Follow naming convention above
- **Documentation:** All commands recorded in GitHub wiki daily log
- **Version control:** All scripts stored in GitHub repository

### Symbolic Links for Raw Data

```bash
# In 00_raw_data/ directory
cd ~/Genome_Analysis_Project/00_raw_data/
ln -s /proj/uppmax2026-1-61/Genome_Analysis/Paper_I/PacBio/*.fastq.gz ./
ln -s /proj/uppmax2026-1-61/Genome_Analysis/Paper_I/RNA_seq/*.fastq.gz ./
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
| eggNOG-mapper | ~13 h | Submit as batch job, run overnight |
| Genome assembly | ~5 h | Submit as batch job or run during reservation |
| RNA-seq alignment | ~30 min × 6 | Submit as array job |
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
| Assembly fails or is highly fragmented | Try alternative assembler (Canu instead of Flye); adjust parameters |
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

### Quality Control Commands

```bash
# FastQC on raw reads
fastqc raw_reads.fastq.gz -o fastqc_before/

# Trimmomatic (paired-end)
trimmomatic PE \
    sample_R1.fastq.gz sample_R2.fastq.gz \
    sample_R1_trimmed.fastq.gz sample_R1_unpaired.fastq.gz \
    sample_R2_trimmed.fastq.gz sample_R2_unpaired.fastq.gz \
    ILLUMINACLIP:adapters.fa:2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

# FastQC after trimming
fastqc *_trimmed.fastq.gz -o fastqc_after/
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
