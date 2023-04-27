process TRINITY {
    tag "$sample_id"

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39": null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trinity%3A2.9.1--h8b12597_1' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), val(fastq1), val(fastq2)
    
    output:
    tuple val(sample_id), path ("${sample_id}_trinity"), emit: trinity_dir
    path "versions.yml", emit: versions


    script:
    normalize_reads = params.trinity_normalize_reads ? "--normalize_reads" : ""
    """
    Trinity \
    ${normalize_reads} \
    --seqType fq \
    --max_memory ${params.trinity_mem}G \
    --left ${fastq1} \
    --right ${fastq2} \
    --CPU ${params.trinity_threads} \
    --output ${sample_id}_trinity \
    --NO_SEQTK
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Trinity: \$(Trinity --version | sed -n '1 p' | sed 's/Trinity version: //g')
    END_VERSIONS
    """
}
