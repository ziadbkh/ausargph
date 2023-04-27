process MERGE_TREES {
    tag "Merging all trees"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    val(tree_list)
    
    output:
    path("AllLoci.trees"), emit: merged_trees
    path "versions.yml", emit: versions

    script:
    
    """
    for tree in ${tree_list.join(' ')}; do
        cat $tree >> AllLoci.trees       
    done



    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP - reformat.sh: \$(reformat.sh -version 2>&1 | sed -n '2 p' | sed 's/BBMap version //g')
    END_VERSIONS
    """
}
