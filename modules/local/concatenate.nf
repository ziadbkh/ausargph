process CONCATENATE {
    tag "$sample_id"

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39": null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), val(fastq)
    val(name_suffix)
    
    output:
    tuple val(sample_id), path("*_${name_suffix}.${params.fastq_suffix}.gz"), emit: concatenated
    path "versions.yml", emit: versions


    script:
    
    """
    zcat ${fastq.join(" ")} | gzip -c > ${sample_id}_${name_suffix}.${params.fastq_suffix}.gz
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        zcat: \$(zcat -V | sed -n '1 p' | sed 's/gzip //g')
        gzip: \$(gzip --version | sed -n '1 p' | sed 's/gzip //g')
    END_VERSIONS
    """
}
