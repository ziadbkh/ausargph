process ASTER {
    tag "Final tree"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/astral-tree%3A5.7.8--hdfd78af_0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    path all_trees
    
    output:
    path("aster_tree_final"), emit: aggregated_tree
    path "versions.yml", emit: versions

    script:
    //locus = fasta.getBaseName().split('.')[0]
    
    """
    astral-hybrid \
    -i ${all_trees} \
    -o aster_tree_final

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP - reformat.sh: \$(reformat.sh -version 2>&1 | sed -n '2 p' | sed 's/BBMap version //g')
    END_VERSIONS
    """
}
