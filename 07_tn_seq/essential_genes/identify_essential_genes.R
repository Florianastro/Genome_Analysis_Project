#!/usr/bin/env Rscript

# Load count data
bhi_files <- list.files("../counts/", pattern = "ERR180101[2-4]_per_gene_counts.txt", full.names = TRUE)
serum_files <- list.files("../counts/", pattern = "ERR180100[9-11]_per_gene_counts.txt", full.names = TRUE)

if (length(bhi_files) > 0 && length(serum_files) > 0) {
    # Read and combine BHI counts
    bhi_counts <- do.call(cbind, lapply(bhi_files, function(f) {
        read.table(f, header = FALSE)[, 4]
    }))
    bhi_mean <- rowMeans(bhi_counts)
    
    # Read and combine Serum counts
    serum_counts <- do.call(cbind, lapply(serum_files, function(f) {
        read.table(f, header = FALSE)[, 4]
    }))
    serum_mean <- rowMeans(serum_counts)
    
    # Gene names
    gene_names <- read.table(bhi_files[1], header = FALSE)[, 4]
    
    # Calculate fold change
    fold_change <- (serum_mean + 1) / (bhi_mean + 1)
    
    # Create results
    results <- data.frame(
        gene = gene_names,
        BHI_mean = bhi_mean,
        Serum_mean = serum_mean,
        FoldChange = fold_change,
        stringsAsFactors = FALSE
    )
    
    # Genes depleted in serum = conditionally essential
    results$essential <- ifelse(results$FoldChange < 0.5 & results$BHI_mean > 10, 
                                  "Conditionally Essential", "Not Essential")
    
    # Sort
    results <- results[order(results$FoldChange), ]
    
    # Save
    write.csv(results, "essential_genes_results.csv", row.names = FALSE)
    
    # Summary
    n_essential <- sum(results$essential == "Conditionally Essential")
    cat("Total genes analyzed:", nrow(results), "\n")
    cat("Conditionally essential genes:", n_essential, "\n")
} else {
    cat("Count files not found. Please run the Tn-seq processing first.\n")
}
