process PEAR {
    tag "$sample_id"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pear%3A0.9.6--h67092d7_8' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path(fastq_r1), path (fastq_r2)
    
    output:
    tuple val(sample_id), path("*.unassembled.forward.${params.fastq_suffix}.gz"), path ("*.unassembled.reverse.${params.fastq_suffix}.gz"), emit: unmerged
    tuple val(sample_id), path ("*.assembled.${params.fastq_suffix}.gz"), emit: merged
    tuple val(sample_id), path ("*.discarded.${params.fastq_suffix}.gz"), emit: discarded

    path "versions.yml", emit: versions

	script:
    
    """
    pear -f ${fastq_r1} -r ${fastq_r2} -o ${sample_id} -j ${task.cpus} ${task.ext.args}
    gzip  *.fastq
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        PEAR: \$(pear -h 2>&1 | sed -n '6 p' | awk '{print \$2}')
        gzip: \$(gzip --version | sed -n '1 p' | sed 's/gzip //g')
    END_VERSIONS
    """
}


