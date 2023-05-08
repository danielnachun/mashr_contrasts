#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --account=smontgom
#SBATCH --cpus-per-task=1
#SBATCH --mem=4GB
#SBATCH --job-name=mashr_contrast
#SBATCH --mail-type=ALL

job_num="${SLURM_ARRAY_TASK_ID}"
posterior_directory="${1}"
orig_directory="${2}"
contrast_directory="${3}"

Rscript get_contrast.R "${posterior_directory}" "${orig_directory}" "${contrast_directory}" "${job_num}"
