process BLAT {
    tag "$sample_id"

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39": null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blat%3A36--0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path(fasta)
    path (db_path)
    val (suffix)
    val (switch_input)
    output:
    tuple val(sample_id), path ("${sample_id}_${suffix}"), emit: matches
    path "versions.yml", emit: versions


    script:
    input = switch_input ? "${db_path}  ${fasta}" : "${fasta} ${db_path}" 
    """
    blat ${input} \
    ${sample_id}_${suffix} \
    -out=blast8
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blat: \$(blat | sed -n '1 p')
    END_VERSIONS
    """
}
