process PERL_CLEANUP {
    tag "$sample_id"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl%3A5.26.2' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path(fasta) //, val(meta)
    
    output:
    //tuple val(sample_id), path("*fasta.aln"), emit: aligned
    path "versions.yml", emit: versions

    script:

    """
    perl -pi -w -e "s/!/N/g;" ${fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blat: \$(blat | sed -n '1 p')
    END_VERSIONS
    """
}
