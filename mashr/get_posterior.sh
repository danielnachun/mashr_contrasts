#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --account=smontgom
#SBATCH --cpus-per-task=1
#SBATCH --mem=4GB
#SBATCH --job-name=mashr_posterior
#SBATCH --mail-type=ALL

job_num="${SLURM_ARRAY_TASK_ID}"
data_directory="${1}"
posterior_directory="${2}"
vhat_file="${3}"
mashr_file="${4}"

Rscript get_posterior.R "${data_directory}" "${posterior_directory}" "${vhat_file}" "${mashr_file}" "${job_num}"
