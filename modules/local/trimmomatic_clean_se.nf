process TRIMMOMATIC_CLEAN_SE {
    tag "$sample_id"

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39": null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trimmomatic%3A0.39--hdfd78af_2' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path(fastq)
    
    output:
    tuple val(sample_id), path("*_unpaired_trimmed_cleaned_se.${params.fastq_suffix}.gz"), emit: trimmed_cleaned_se
    path "versions.yml", emit: versions


    script:
    
    """
    trimmomatic SE \
    -threads ${params.trimmomatic_clean_threads} \
    -phred33 \
    ${fastq} \
    ${sample_id}_unpaired_trimmed_cleaned_se.${params.fastq_suffix}.gz \
    LEADING:${params.trimmomatic_clean_head} \
    TRAILING:${params.trimmomatic_clean_trail} \
    SLIDINGWINDOW:4:${params.trimmomatic_clean_qual} \
    MINLEN:${params.trimmomatic_clean_minlength}
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimmomatic: \$(trimmomatic -version)
    END_VERSIONS
    """
}
