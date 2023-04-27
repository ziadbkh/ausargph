process IQTREE {
    tag "$fasta"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree%3A2.2.2.3--hb97b32f_0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    val(fasta_ls)
    
    output:
    path("RAxML_info*"), emit: tree_info
    path("RAxML_bootstrap*"), emit: tree_bootstrap
    path("RAxML_bipartitionsBranchLabels*"), emit: tree_bipartitions_branch_labels
    path("RAxML_bipartitions*"), emit: tree_bipartitions
    path("RAxML_bestTree*"), emit: best_tree
    path "versions.yml", emit: versions

    script:
    //locus = fasta.getBaseName().split('.')[0]
    
    """
     for fasta in ${fasta_ls.join(' ')}; do
        file_lines=\$(cat \$fasta | wc -l)
        if [ \$file_lines -gt 0 ]
        then
            sp_cnt=\$(cat \$fasta | grep \\> | wc -l)
            if [ \$sp_cnt -lt 4 ]
            then
                echo "\$fasta" >> fasta_few_specieis.txt
            else
                locus="\$(basename -- "\$fasta" | sed 's/\\(.*\\)\\..*/\\1/')"
                rand1=\$[ ( \$RANDOM % 1000 )  + 1 ]
                rand2=\$[ ( \$RANDOM % 1000 )  + 1 ]
                
                raxmlHPC -x \$rand1 -# ${params.raxml_runs} -p \$rand2 ${task.ext.args} -n \${locus} -s \${fasta}
                
            fi
        else
            echo "\$fasta" >> empty_fastq.txt
        fi       
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        BBMAP - reformat.sh: \$(reformat.sh -version 2>&1 | sed -n '2 p' | sed 's/BBMap version //g')
    END_VERSIONS
    """
}
