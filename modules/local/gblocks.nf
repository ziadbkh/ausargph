process GBLOCKS {
    tag "$fasta"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gblocks%3A0.91b--h9ee0642_2' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    val(fasta_ls)
    
    output:
    path("*-gb"), emit: trimmed_allignments
    path "versions.yml", emit: versions

    script:
    
    """
    for fasta in ${fasta_ls.join(' ')}; do
        file_base_name="\$(basename -- "\$fasta")"
        ln -s "\${fasta}" \$file_base_name  
        num_seq=\$(cat \${fasta} | grep \\> | wc -l)
        
        b1=\$(awk "BEGIN {printf \\"%.0f\\", ${task.ext.gblocks_b1} * \$num_seq + 0.5}")
        
        b2=\$(awk "BEGIN {printf \\"%.0f\\", ${task.ext.gblocks_b2} * \$num_seq}")
        
        if [ \$b2 -lt \$b1 ]
        then
            b2=\$b1
        fi

        Gblocks \${file_base_name}  -b1=\$b1  -b2=\$b2  ${task.ext.args} || true
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP - reformat.sh: \$(reformat.sh -version 2>&1 | sed -n '2 p' | sed 's/BBMap version //g')
    END_VERSIONS
    """
}
