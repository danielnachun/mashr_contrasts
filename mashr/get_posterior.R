library(mashr)
library(tidyverse)

command_args <- commandArgs(trailingOnly = TRUE)
data_dir <- command_args[1]
posterior_dir <- command_args[2]
vhat_file <- command_args[3]
mashr_file <- command_args[4]
job_num <- command_args[5]

mashr_posterior_file <- str_c(posterior_dir, "/posterior_", job_num, ".rda")
if (!file.exists(mashr_posterior_file)) {
    data_file <- str_c(data_dir, "/data_slice_", job_num, ".rda")
    data_rows <- read_rds(data_file)

    vhat <- read_rds(vhat_file)
    mashr_fit <- read_rds(mashr_file)

    data_rows_beta <- select(data_rows, BETA_ESN:BETA_YRI) %>% as.matrix
    data_rows_se <- select(data_rows, SE_ESN:SE_YRI) %>% as.matrix
    data_rows_mash <- mash_set_data(data_rows_beta, data_rows_se, V = vhat)
    mashr_posterior <- mash(data_rows_mash, g = get_fitted_g(mashr_fit), fixg = TRUE, outputlevel = 4)

    write_rds(mashr_posterior, mashr_posterior_file)
}
