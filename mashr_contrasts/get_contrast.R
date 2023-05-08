library(mashr)
library(RhpcBLASctl)
blas_set_num_threads(1)
library(magrittr)
library(tidyverse)

command_args <- commandArgs(trailingOnly = TRUE)
posterior_dir <- command_args[1]
orig_dir <- command_args[2]
contrast_dir <- command_args[3]
job_num <- command_args[4]

#Testing code
#posterior_dir <- "~/montgomery_lab/projects/Africa_eqtls/eqtl_posterior"
#orig_dir <- "~/montgomery_lab/projects/Africa_eqtls/eqtl_split"
#contrast_dir <- "~/montgomery_lab/projects/Africa_eqtls/eqtl_contrast"
#job_num <- 96

contrast_file <- str_c(contrast_dir, "/contrast_", job_num, ".rda")

if (!file.exists(contrast_file)) {
    MakePairwiseContrastCols <- function(contrast_left, orig_vector) { 
        orig_vector[contrast_left[1]] <- 1
        orig_vector[contrast_left[2]] <- -1
        orig_vector
    }

    FitContrast <- function(index, orig_mean, posterior_mean, posterior_vcov) {
        print(index)
        population_names <- colnames(posterior_mean) %>% str_remove_all("BETA_")

        orig_mean_vector <- orig_mean[index,]
        names(orig_mean_vector) <- population_names
        orig_mean_nonzero <- as.vector(orig_mean_vector != 0)
        orig_mean_tested <- names(orig_mean_vector[orig_mean_nonzero])
        n_populations <- length(orig_mean_tested)

        pairwise_vector <- rep(0, n_populations) 
        names(pairwise_vector) <- orig_mean_tested

        if (n_populations > 1) {
            if (n_populations > 2) {
                deviation_contrasts <- rep(-1, n_populations ^ 2) %>% matrix(nrow = n_populations, ncol = n_populations) 
                diag(deviation_contrasts) <- n_populations - 1
                rownames(deviation_contrasts) <- orig_mean_tested
                colnames(deviation_contrasts) <- orig_mean_tested
                deviation_contrasts_tested <- deviation_contrasts[,orig_mean_tested]
                colnames(deviation_contrasts_tested) %<>% str_c("_deviation")

                two_combn <- combn(orig_mean_tested, m = 2) 
                pairwise_names <- apply(two_combn, 2, str_c, collapse = "_vs_") 
                pairwise_contrast <- apply(two_combn, 2, MakePairwiseContrastCols, pairwise_vector) 
                colnames(pairwise_contrast) <- pairwise_names

                contrast_design <- cbind(deviation_contrasts_tested / (n_populations - 1), pairwise_contrast) 
            } else {
                pairwise_vector[orig_mean_tested[1]] <- 1
                pairwise_vector[orig_mean_tested[2]] <- -1
                contrast_design <- as.matrix(pairwise_vector) 
                colnames(contrast_design) <- str_c(orig_mean_tested[1], "_vs_", orig_mean_tested[2])
            }

            posterior_mean_subset <- posterior_mean[index,]
            names(posterior_mean_subset) %<>% str_remove_all("BETA_")
            posterior_mean_subset2 <- posterior_mean_subset[orig_mean_tested]
            posterior_vcov_subset <- posterior_vcov[,,index]
            colnames(posterior_vcov_subset) %<>% str_remove_all("BETA_")
            rownames(posterior_vcov_subset) %<>% str_remove_all("BETA_")
            posterior_vcov_subset2 <- posterior_vcov_subset[orig_mean_tested,orig_mean_tested]

            contrast_diff <- t(contrast_design) %*% posterior_mean_subset2
            contrast_vcov <- t(contrast_design) %*% posterior_vcov_subset2 %*% contrast_design
            contrast_se <- diag(contrast_vcov) %>% sqrt

            contrast_p <- 2 * (1 - pnorm(abs(contrast_diff) / contrast_se))

            contrast_diff_df <- t(contrast_diff) %>% as_tibble
            colnames(contrast_diff_df) %<>% str_c("mean_contrast_", .)
            contrast_se_df <- t(contrast_se) %>% as_tibble
            colnames(contrast_se_df) %<>% str_c("se_contrast_", .)
            contrast_p_df <- t(contrast_p) %>% as_tibble
            colnames(contrast_p_df) %<>% str_c("p_contrast_", .)

            contrast_df <- bind_cols(contrast_diff_df, contrast_se_df, contrast_p_df)
        } else {
            contrast_vector <- rep(NA, length(population_names))
            names(contrast_vector) <- str_c("mean_contrast_", population_names, "_deviation")
            contrast_df <- t(contrast_vector) %>% as_tibble
        }
        contrast_df
    }

    posterior_file <- str_c(posterior_dir, "/posterior_", job_num, ".rda")
    posterior_data <- read_rds(posterior_file)

    posterior_mean <- posterior_data$result$PosteriorMean
    posterior_cov <- posterior_data$result$PosteriorCov

    orig_file <- str_c(orig_dir, "/data_slice_", job_num, ".rda")
    orig_data <- read_rds(orig_file) %>% select(contains("BETA"))

    contrast_result <- map(1:nrow(posterior_mean), FitContrast, orig_data, posterior_mean, posterior_cov) %>% bind_rows %>%
        select(matches("mean_contrast.*deviation"), matches("mean_contrast.*_vs_"), 
            matches("se_contrast.*deviation"), matches("se_contrast.*_vs_"), 
            matches("p_contrast.*deviation"), matches("p_contrast.*_vs_"))

    write_rds(contrast_result, contrast_file)
}
