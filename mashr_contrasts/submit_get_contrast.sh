#!/bin/bash

if [ -z "${1}" ]; then
    echo "submit_get_posterior [posterior_directory] [contrast_directory]"
    echo "posterior_directory: path to posteriors"
    echo "orig_directory: path to original summary stats"
    echo "contrast_directory: path to save contrasts"
else
    posterior_directory=${1}
    orig_directory="${2}"
    contrast_directory="${3}"
    file_list="$(dirname "${posterior_directory}")/posterior_files"

    mkdir -p "${contrast_directory}/Logs"

    code_directory="/oak/stanford/groups/smontgom/dnachun/workflows/mashr_contrasts" #specify location of star_align_and_qc.sh

    find -L "${posterior_directory}/" -type f | grep rda | sort -u > "${file_list}" #generate list of full paths to fastq files and save to the file in $fastq_list
    array_length=$(wc -l < "${file_list}") #get the number of files 

    #Note - do NOT delete the the '\' or '`' characters - they allow the command to have multiple lines with comments!
    sbatch -o "${contrast_directory}/Logs/%A_%a.log" `#put into log` \
        -a "1-${array_length}%100" `#initiate job array equal to the number of files` \
        "${code_directory}/get_contrast.sh" `#specify get_contrast script` \
        "${posterior_directory}" \
        "${orig_directory}" \
        "${contrast_directory}" 
fi


