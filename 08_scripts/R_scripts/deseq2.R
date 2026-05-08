#!/usr/bin/env Rscript
# ============================================================
# DESeq2 Differential Expression Analysis
# E. faecium E745: Serum vs BHI
# Based on Zhang et al. (2017)
# ============================================================

# Load required libraries
library(DESeq2)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)

# Set working directory
setwd("/home/qich5654/Genome_Analysis_Project")

# Create output directory
dir.create("06_rna_seq/deseq2_results", showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Step 1: Load count data
# ============================================================

cat("Loading count data...\n")

# Define sample files
sample_files <- c(
    "06_rna_seq/counts/ERR1797972_counts.txt",
    "06_rna_seq/counts/ERR1797973_counts.txt",
    "06_rna_seq/counts/ERR1797974_counts.txt",
    "06_rna_seq/counts/ERR1797969_counts.txt",
    "06_rna_seq/counts/ERR1797970_counts.txt",
    "06_rna_seq/counts/ERR1797971_counts.txt"
)

# Read count files
count_list <- lapply(sample_files, function(f) {
    read.table(f, header = FALSE, stringsAsFactors = FALSE, row.names = 1)
})

# Combine into a single matrix
count_matrix <- do.call(cbind, count_list)

# Set column names
colnames(count_matrix) <- c(
    "BHI_1", "BHI_2", "BHI_3",
    "Serum_1", "Serum_2", "Serum_3"
)

# Remove lines that don't correspond to genes (e.g., __no_feature, __ambiguous)
gene_rows <- !grepl("^__", rownames(count_matrix))
count_matrix <- count_matrix[gene_rows, ]

cat("Number of genes:", nrow(count_matrix), "\n")
cat("Count matrix dimensions:", dim(count_matrix), "\n")

# Save raw count matrix
write.csv(count_matrix, "06_rna_seq/deseq2_results/raw_counts.csv")
cat("Raw count matrix saved.\n\n")

# ============================================================
# Step 2: Create DESeq2 dataset
# ============================================================

cat("Creating DESeq2 dataset...\n")

# Create sample metadata
colData <- data.frame(
    row.names = colnames(count_matrix),
    condition = factor(c(
        rep("BHI", 3),
        rep("Serum", 3)
    )),
    replicate = factor(c(
        "1", "2", "3",
        "1", "2", "3"
    ))
)

# Create DESeq2 object
dds <- DESeqDataSetFromMatrix(
    countData = count_matrix,
    colData = colData,
    design = ~ condition
)

cat("DESeq2 dataset created.\n")
cat("Number of samples:", ncol(dds), "\n")
cat("Conditions:", levels(colData$condition), "\n\n")

# ============================================================
# Step 3: Pre-filtering
# ============================================================

cat("Pre-filtering low count genes...\n")

# Keep genes with at least 10 counts total across all samples
dds <- dds[rowSums(counts(dds)) >= 10, ]

cat("Genes after filtering:", nrow(dds), "\n\n")

# ============================================================
# Step 4: Run DESeq2
# ============================================================

cat("Running DESeq2...\n")
dds <- DESeq(dds)
cat("DESeq2 analysis complete!\n\n")

# ============================================================
# Step 5: Extract results
# ============================================================

cat("Extracting differential expression results...\n")

# Get results for Serum vs BHI comparison
res <- results(
    dds,
    contrast = c("condition", "Serum", "BHI"),
    alpha = 0.05
)

# Order by adjusted p-value
res <- res[order(res$padj), ]

# Summary of results
cat("\nDESeq2 Results Summary:\n")
summary(res)

# ============================================================
# Step 6: Annotate with significance categories
# ============================================================

# Define significance thresholds (matching the paper: q < 0.001, |fold change| > 2)
res$significant <- ifelse(
    !is.na(res$padj) & res$padj < 0.001 & abs(res$log2FoldChange) > 1,
    "Significant",
    "Not Significant"
)

res$direction <- ifelse(
    res$significant == "Significant",
    ifelse(res$log2FoldChange > 0, "Upregulated", "Downregulated"),
    "Not Significant"
)

# Count differentially expressed genes
sig_genes <- sum(res$significant == "Significant", na.rm = TRUE)
up_genes <- sum(res$direction == "Upregulated", na.rm = TRUE)
down_genes <- sum(res$direction == "Downregulated", na.rm = TRUE)

cat("\nDifferentially expressed genes (q < 0.001, |FC| > 2):", sig_genes, "\n")
cat("  Upregulated in Serum:", up_genes, "\n")
cat("  Downregulated in Serum:", down_genes, "\n")

# ============================================================
# Step 7: Save results
# ============================================================

# Save full results table
res_df <- as.data.frame(res)
res_df$gene_id <- rownames(res_df)
write.csv(res_df, "06_rna_seq/deseq2_results/differential_expression_results.csv", 
          row.names = FALSE)

# Save significant genes only
sig_res <- res_df[res_df$significant == "Significant" & !is.na(res_df$significant), ]
write.csv(sig_res, "06_rna_seq/deseq2_results/significant_genes.csv", 
          row.names = FALSE)

cat("Results saved to:\n")
cat("  - 06_rna_seq/deseq2_results/differential_expression_results.csv\n")
cat("  - 06_rna_seq/deseq2_results/significant_genes.csv\n\n")

# ============================================================
# Step 8: Visualizations
# ============================================================

cat("Generating visualizations...\n")

# 8a. MA Plot
png("06_rna_seq/deseq2_results/MA_plot.png", width = 800, height = 600)
plotMA(res, ylim = c(-10, 10), main = "MA Plot: Serum vs BHI")
abline(h = c(-1, 1), col = "blue", lty = 2)
dev.off()
cat("  - MA plot saved.\n")

# 8b. Volcano Plot
png("06_rna_seq/deseq2_results/volcano_plot.png", width = 800, height = 600)

volcano_data <- as.data.frame(res)
volcano_data <- volcano_data[!is.na(volcano_data$padj), ]

ggplot(volcano_data, aes(x = log2FoldChange, y = -log10(padj), color = direction)) +
    geom_point(alpha = 0.6, size = 2) +
    scale_color_manual(values = c(
        "Upregulated" = "#E41A1C",
        "Downregulated" = "#377EB8",
        "Not Significant" = "#AAAAAA"
    )) +
    geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "grey50") +
    geom_hline(yintercept = -log10(0.001), linetype = "dashed", color = "grey50") +
    labs(
        title = "Volcano Plot: Serum vs BHI",
        x = "Log2 Fold Change",
        y = "-Log10 Adjusted P-value"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")

dev.off()
cat("  - Volcano plot saved.\n")

# 8c. PCA Plot
png("06_rna_seq/deseq2_results/PCA_plot.png", width = 800, height = 600)

vsd <- vst(dds, blind = FALSE)
pca_data <- plotPCA(vsd, intgroup = "condition", returnData = TRUE)
percent_var <- round(100 * attr(pca_data, "percentVar"))

ggplot(pca_data, aes(PC1, PC2, color = condition, shape = condition)) +
    geom_point(size = 4) +
    labs(
        title = "PCA: RNA-seq Samples",
        x = paste0("PC1: ", percent_var[1], "% variance"),
        y = paste0("PC2: ", percent_var[2], "% variance")
    ) +
    theme_minimal()

dev.off()
cat("  - PCA plot saved.\n")

# 8d. Heatmap of top 50 DEGs
png("06_rna_seq/deseq2_results/heatmap_top50.png", width = 1000, height = 1200)

top_genes <- head(rownames(res_df[res_df$significant == "Significant" & !is.na(res_df$significant), ]), 50)
if (length(top_genes) > 0) {
    mat <- counts(dds, normalized = TRUE)[top_genes, ]
    mat <- t(scale(t(mat)))
    
    annotation_col <- data.frame(
        Condition = colData$condition,
        row.names = rownames(colData)
    )
    
    pheatmap(
        mat,
        annotation_col = annotation_col,
        show_rownames = TRUE,
        cluster_cols = TRUE,
        cluster_rows = TRUE,
        main = "Top 50 Differentially Expressed Genes\nSerum vs BHI",
        fontsize_row = 6
    )
} else {
    plot.new()
    text(0.5, 0.5, "No significant genes found", cex = 1.5)
}

dev.off()
cat("  - Heatmap saved.\n")

# ============================================================
# Step 9: Check purine biosynthesis genes from the paper
# ============================================================

cat("\n============================================\n")
cat("  Checking Key Genes from Zhang et al. (2017)\n")
cat("============================================\n")

# List of key genes identified in the paper
key_genes <- c("purD", "purH", "purL", "purC", "purQ", "purA", "guaB",
               "pyrF", "pyrK_2", "manY_2", "manZ_3", "ptsI")

cat("\nExpression of key genes:\n")
for (gene in key_genes) {
    # Search for the gene in results
    matches <- rownames(res_df)[grep(gene, rownames(res_df), ignore.case = TRUE)]
    
    if (length(matches) > 0) {
        for (match in matches) {
            res_line <- res_df[match, ]
            cat(sprintf("  %-30s  log2FC: %6.2f  padj: %8.2e  %s\n",
                       match,
                       res_line$log2FoldChange,
                       res_line$padj,
                       res_line$direction))
        }
    }
}

# ============================================================
# Step 10: Summary report
# ============================================================

cat("\n============================================\n")
cat("  Differential Expression Analysis Complete!\n")
cat("============================================\n")
cat("\n")
cat(sprintf("Total genes analyzed:        %d\n", nrow(res_df)))
cat(sprintf("Significantly DEGs:          %d\n", sig_genes))
cat(sprintf("  Upregulated in Serum:       %d\n", up_genes))
cat(sprintf("  Downregulated in Serum:     %d\n", down_genes))
cat("\n")
cat("Output files saved to: 06_rna_seq/deseq2_results/\n")
cat("  1. differential_expression_results.csv - Full results\n")
cat("  2. significant_genes.csv              - Significant DEGs only\n")
cat("  3. MA_plot.png                        - MA plot\n")
cat("  4. volcano_plot.png                   - Volcano plot\n")
cat("  5. PCA_plot.png                       - PCA plot\n")
cat("  6. heatmap_top50.png                  - Heatmap of top 50 DEGs\n")
cat("\n")
cat("Session information:\n")
sessionInfo()
