process MAFFT {
    tag "$fasta"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mafft%3A7.520--hec16e2b_0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    val (fasta_ls)
    
    output:
    path("*fasta.aln"), emit: aligned
    path "versions.yml", emit: versions

    script:
    """
    for fasta in ${fasta_ls.join(' ')}; do
        f_out="\$(basename -- "\$fasta" | sed 's/\\(.*\\)\\..*/\\1/')"
        mafft ${task.ext.args} \${fasta} > \${f_out}.fasta.aln  

    done

    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blat: \$(blat | sed -n '1 p')
    END_VERSIONS
    """
}
