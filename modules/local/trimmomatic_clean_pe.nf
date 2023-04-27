process TRIMMOMATIC_CLEAN_PE {
    tag "$sample_id"

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39": null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trimmomatic%3A0.39--hdfd78af_2' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), val(fastq1), val(fastq2)
    
    output:
    tuple val(sample_id), path("*_R1_paired_trimmed_cleaned.${params.fastq_suffix}.gz"), path ("*_R2_paired_trimmed_cleaned.${params.fastq_suffix}.gz"), emit: trimmed_cleaned_paired
    tuple val(sample_id), path ("*_R1_unpaired_trimmed_cleaned.${params.fastq_suffix}.gz"), path ("*_R2_unpaired_trimmed_cleaned.${params.fastq_suffix}.gz"), emit: trimmed_cleaned_unpaired
    path "versions.yml", emit: versions


    script:
    
    """
    trimmomatic PE \
        -threads  ${task.cpus} \
        ${fastq1} \
        ${fastq2} \
        ${sample_id}_R1_paired_trimmed_cleaned.${params.fastq_suffix}.gz \
        ${sample_id}_R1_unpaired_trimmed_cleaned.${params.fastq_suffix}.gz \
        ${sample_id}_R2_paired_trimmed_cleaned.${params.fastq_suffix}.gz \
        ${sample_id}_R2_unpaired_trimmed_cleaned.${params.fastq_suffix}.gz \
        ${task.ext.args}
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimmomatic: \$(trimmomatic -version)
    END_VERSIONS
    """
}
