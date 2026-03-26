args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript chi-fisher_test.R input.tsv output.tsv")
}
 
input_file <- args[1]
output_file <- args[2]

# Read input
counts <- read.csv(input_file, row.names = 1, sep = "\t")

# Domain group sizes
groupA_size <- 5203
groupB_size <- 135832

# Initialize result containers
p_values <- rep(NA, nrow(counts))
direction_A <- rep(NA, nrow(counts))
test_types <- rep(NA, nrow(counts))

for (cat_ind in 1:nrow(counts)) {
  cat_counts <- counts[cat_ind, ]
  not_cat_counts <- c(groupA_size - cat_counts[1], groupB_size - cat_counts[2])
  contingency_table <- matrix(c(as.numeric(cat_counts), as.numeric(not_cat_counts)), nrow = 2)
  dimnames(contingency_table) <- list(c("groupA", "groupB"), c("cat_x", "not_cat_x"))
  
  testType <- "CHI"
  test_res <- tryCatch({
    chisq.test(contingency_table, correct = TRUE)
  }, warning = function(w) {
    testType <<- "FISHER"
    fisher.test(contingency_table)
  })
  
  p_value <- test_res$p.value
  if ("residuals" %in% names(test_res)) {
    direction_A[cat_ind] <- test_res$residuals[1, 1]
  } else {
    direction_A[cat_ind] <- test_res$estimate
  }
  
  p_values[cat_ind] <- p_value
  test_types[cat_ind] <- testType
}

# Multiple testing correction
p_adjusted <- p.adjust(p_values, method = "BH")

# Save results
result_df <- data.frame(
  Category = rownames(counts),
  raw_count_A = counts[, 1],
  raw_count_B = counts[, 2],
  test_type = test_types,
  p_value = p_values,
  p_adjusted = p_adjusted,
  direction = direction_A
)

write.table(result_df, file = output_file, sep = "\t", row.names = FALSE, quote = FALSE)

cat("Results saved to", output_file, "\n")
