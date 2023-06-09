process CONCATENATE_RAW {
    tag "$sample_id"

    conda (params.enable_conda ? "": null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path fastq1, path fastq2
    val(name_suffix)
    
    output:
    tuple val(sample_id), path("*_${name_suffix}_R1.${params.fastq_suffix}.gz"), path("*_${name_suffix}_R2.${params.fastq_suffix}.gz"), emit: concatenated
    path "versions.yml", emit: versions


    script:
    
    """
    zcat ${fastq1.join(" ")} | gzip -c > ${sample_id}_${name_suffix}_R1.${params.fastq_suffix}.gz
    zcat ${fastq2.join(" ")} | gzip -c > ${sample_id}_${name_suffix}_R2.${params.fastq_suffix}.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        zcat: \$(zcat -V | sed -n '1 p' | sed 's/gzip //g')
        gzip: \$(gzip --version | sed -n '1 p' | sed 's/gzip //g')
    END_VERSIONS
    """
}
