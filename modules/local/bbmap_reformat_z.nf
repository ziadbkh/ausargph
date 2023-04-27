process BBMAP_REFORMAT_Z {
    tag "$fasta"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bbmap%3A39.01--h5c4e2a8_0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    val(fasta_ls) //, val(meta)
    
    output:
    path "*.fasta", emit: reformated
    path "versions.yml", emit: versions

    script:
    """
    for fasta in ${fasta_ls.join(' ')}; do
        file_base_name="\$(basename -- "\$fasta")"
        reformat.sh in=\${fasta} out=\${file_base_name}.fasta  ${task.ext.args}
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP - reformat.sh: \$(reformat.sh -version 2>&1 | sed -n '2 p' | sed 's/BBMap version //g')
    END_VERSIONS
    """
}
