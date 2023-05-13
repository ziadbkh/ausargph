process ASTER {
    tag "Final Tree"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/aster%3A1.15--h9f5acd7_0' :
        'quay.io/biocontainers/aster:1.15--h9f5acd7_1' }"

    input:
    path all_trees
    
    output:
    path("aster_tree_final"), emit: final_tree
    path "versions.yml", emit: versions

    script:
    //locus = fasta.getBaseName().split('.')[0]
    
    """
    astral-hybrid \
    -i ${all_trees} \
    -o aster_tree_final

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP - reformat.sh: 
    END_VERSIONS
    """
}
