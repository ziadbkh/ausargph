process MACSE {
    tag "$sample_id"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/macse%3A2.07--hdfd78af_0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path(fasta) //, val(meta)
    val macse_program

    output:
    tuple val(sample_id), path("*NT.fasta"), emit: nt_fasta
    tuple val(sample_id), path("*AA.fasta"), emit: aa_fasta
    path "versions.yml", emit: versions

    script:

    specific_argumenent = ""
    if (macse_program == "refine"){
        specific_argumenent = "-align ${fasta} ${task.ext.args_refine} "
    }else if (macse_program == "refineLemmon"){
        specific_argumenent = " -align ${fasta} ${task.ext.args_refineLemmon} "
    }else if (macse_program == "export"){
        specific_argumenent = " -align ${fasta} ${task.ext.args_export} "
    }else if (macse_program == "align"){
        specific_argumenent = " -seq_lr ${fasta} ${task.ext.args_align} "
    }
    """
    macse ${specific_argumenent}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blat: \$(blat | sed -n '1 p')
    END_VERSIONS
    """
}
