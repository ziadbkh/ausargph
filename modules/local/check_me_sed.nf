process SED {
    tag "$fasta"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    val (fasta_ls)
    
    output:
    path("*.sed.fasta"), emit: seded
    path "versions.yml", emit: versions

    script:
    """
    for fasta in ${fasta_ls.join(' ')}; do
        file_base_name="\$(basename -- "\$fasta")"
        sed \
        -r 's/\s+//g' \
        \${fasta} | sed -r 's/_R_//g' > \${file_base_name}.sed.fasta
    done
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: \$(sed --version | sed -n '1 p' | sed 's/sed (GNU sed) //g')
    END_VERSIONS
    """
}
