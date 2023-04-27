process MACSE {
    tag "$sample_id"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/macse%3A2.07--hdfd78af_0' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(sample_id), path(fasta) //, val(meta)
    
    output:
    tuple val(sample_id), path("*NT.fasta"), emit: nt_fasta
    tuple val(sample_id), path("*AA.fasta"), emit: aa_fasta
    path "versions.yml", emit: versions

    script:

    specific_argumenent = ""
    if (params.macse_program == "refine"){
        specific_argumenent = "-prog refineAlignment -align ${fasta} -stop ${params.macse_stop}"
    }else if (params.macse_program == "refineLemmon"){
        specific_argumenent = "-prog refineAlignment -align ${fasta} \
        -optim ${params.macse_refine_alignment_optim} \
        -local_realign_init ${params.macse_refine_alignment_local_realign_init} \
        -local_realign_dec ${params.macse_refine_alignment_local_realign_dec} \
        -fs ${params.macse_refine_alignment_fs}"
    }else if (params.macse_program == "export"){
        specific_argumenent = "-prog exportAlignment -align ${fasta} -stop ${params.macse_stop}"
    }else if (params.macse_program == "align"){
        specific_argumenent = "-prog alignSequences -seq_lr ${fasta} -stop_lr ${params.macse_stop}"
    }
    """
    macse \
    ${specific_argumenent}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blat: \$(blat | sed -n '1 p')
    END_VERSIONS
    """
}
