process BBMAP_FILTER{
tag "$sample_id"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bbmap%3A39.01--h5c4e2a8_0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path(fastq_r1), path(fastq_r2)
    path (reference_genome)
    output:
    tuple val(sample_id), 
            path ("${sample_id}_R1_bbmap.${params.fastq_suffix}.gz"), 
            path ("${sample_id}_R2_bbmap.${params.fastq_suffix}.gz") , emit: prepared_reads
    path "versions.yml", emit: versions

    script:
    
    //input = meta.single_end ? "in=${fastq}" : "in=${fastq[0]} in2=${fastq[1]}"
    //fastq_r1 = fastq[0]
    //fastq_r2 = fastq[1]
    //-Xmx{task.memory}g
    input = "in=${fastq_r1} in2=${fastq_r2}"
    
    """
    bbmap.sh in1=${fastq_r1} in2=${fastq_r2} \
        ref=${reference_genome} \
        outm1=${sample_id}_R1_bbmap.${params.fastq_suffix}.gz \
        outm2=${sample_id}_R2_bbmap.${params.fastq_suffix}.gz \
        -Xmx${task.memory.toGiga()}g ${task.ext.args} threads=${task.cpus}
						
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP - bbmap.sh: \$(bbamp.sh -version 2>&1 | sed -n '2 p' | sed 's/BBMap version //g')
    END_VERSIONS
    """
}
