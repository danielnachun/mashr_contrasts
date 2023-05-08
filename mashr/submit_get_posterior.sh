#!/bin/bash

if [ -z "${1}" ]; then
    echo "submit_get_posterior [data_directory] [posterior_directory] [vhat_file] [mashr_file]"
    echo "data_directory: path to original eQTL files"
    echo "posterior_directory: path to save posteriors"
    echo "vhat_file: path to vhat.rda file"
    echo "mashr_file: path to mash_fit.rda file"
else
    data_directory="${1}"
    posterior_directory=$2 
    vhat_file=$3 
    mashr_file=$4 
    file_list="$(dirname "${data_directory}")/data_files"

    mkdir -p "${posterior_directory}/Logs"

    code_directory="/oak/stanford/groups/smontgom/dnachun/workflows/mashr" #specify location of star_align_and_qc.sh

    find -L "${data_directory}/" -type f | grep rda | sort -u > "${file_list}" #generate list of full paths to fastq files and save to the file in $fastq_list
    array_length=$(wc -l < "${file_list}") #get the number of files 

    #Note - do NOT delete the the '\' or '`' characters - they allow the command to have multiple lines with comments!
    sbatch -o "${posterior_directory}/Logs/%A_%a.log" `#put into log` \
        -a "1-${array_length}" `#initiate job array equal to the number of files` \
        "${code_directory}/get_posterior.sh" `#specify get_posterior script` \
        "${data_directory}" \
        "${posterior_directory}" \
        "${vhat_file}" \
        "${mashr_file}"
fi


