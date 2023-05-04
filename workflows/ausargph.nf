/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowAusargph.initialise(params, log)
// TODO nf-core: Add all file path parameters for the pipeline to the list below

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.reference_genome, params.blat_db ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
//if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input directory is not specified!' }
//if (params.meta) { ch_input = file(params.input) } else { exit 1, 'Input directory is not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BBMAP_DEDUPE } from '../modules/local/bbmap_dedupe'
include { PREPARE_ADAPTOR } from '../modules/local/prepare_adaptor'

include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { PREPARE_SAMPLESHEET } from '../modules/local/prepare_samplesheet'
include { BBMAP_REFORMAT } from '../modules/local/bbmap_reformat'
include { TRIMMOMATIC } from '../modules/local/trimmomatic'
include { PEAR } from '../modules/local/pear'
include { CONCATENATE } from '../modules/local/concatenate'
include { CONCATENATE as CONCATENATE2 } from '../modules/local/concatenate'
include { CONCATENATE as CONCATENATE3 } from '../modules/local/concatenate'
include {TRIMMOMATIC_CLEAN_PE} from '../modules/local/trimmomatic_clean_pe'
include {TRIMMOMATIC_CLEAN_SE} from '../modules/local/trimmomatic_clean_se'

include {BBMAP_FILTER} from '../modules/local/bbmap_filter'
include {TRINITY} from '../modules/local/trinity'
include {TRINITY_POSTPROCESSING} from '../modules/local/trinity_postprocessing'
include {BLAT} from '../modules/local/blat'
include {BLAT as BLAT2} from '../modules/local/blat'
include {PARSE_BLAT_RESULTS} from '../modules/local/parse_blat_results'
include {MAFFT} from '../modules/local/mafft'
include { MACSE } from '../modules/local/macse'
include {PERL_CLEANUP} from '../modules/local/perl_cleanup'

include {MAKE_PRG} from '../modules/local/make_prg'
include {QUALITY_2_ASSEMBLY} from '../modules/local/quality_2_assembly'
include {PHYLOGENY_MAKE_ALIGNMENTS} from '../modules/local/phylogeny_make_alignments'
include { GBLOCKS } from '../modules/local/gblocks'

include { CONVERT_PHYML } from '../modules/local/convert_phyml'
include { RAXML } from '../modules/local/raxml'
include { SED } from '../modules/local/check_me_sed'
include { BBMAP_REFORMAT_Z } from '../modules/local/bbmap_reformat_z.nf'
include { MERGE_TREES } from '../modules/local/merge_trees.nf'
include { ASTER } from '../modules/local/aster.nf'

//include 
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

//Example: include { FASTQC                      } from '../modules/nf-core/modules/fastqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
workflow AUSARGPH {
    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    
    //zz = { check_max( params.bbmap_filter_cpus    * task.attempt, 'cpus' ) }
        
    //println zz;

    Channel
        .fromPath(params.reference_genome, checkIfExists:true)
        .collect()
        .set{ch_reference_genome}
    
    Channel
        .fromPath(params.blat_db, checkIfExists:true)
        .collect()
        .set{ch_blat_db}

    //ch_reference_genome.view()
    if (false){
        Channel
        .fromPath(params.input + '*.fastq')
        .map {it -> tuple(it.getFileName().toString().split('_')[0] + '_' + it.getFileName().toString().split('_')[2], it) }
        .groupTuple(sort:true)
        .map{it -> tuple(it[0].split('_')[0], it[1]) }
        .groupTuple()
        .set{ch_fastq_lanes}

        Channel
        .fromPath(params.meta)
        .splitCsv(header:true, strip:true)
        .map {row -> tuple(row.sample_id, tuple(row.genus, row.species, row.library_id, row.sample_id)) }
        .set{ch_meta}

        //ch_fastq_lanes.view()
        //ch_meta.view()
        //ch_fastq_lanes.join(ch_meta).view()

        PREPARE_SAMPLESHEET(ch_fastq_lanes.join(ch_meta)) 
    }else{
        //fix the format
        Channel
        .fromFilePairs(params.input + '*_R{1,2}*.fastq.gz', checkIfExists:true)
        .set{ch_prepared_fastq}

        Channel
        .fromPath( file( params.meta ) )
        .splitCsv(header:true, strip:true)
        .map {row -> tuple(row.sample_id, 
                           tuple(row.adaptor1, row.adaptor2, row.barcode1, row.barcode2, row.lineage)
                    ) 
             }
        .set{ch_sample_sheet}

        ch_sample_sheet.map{it -> [it[0], [it[1][0], it[1][1], it[1][2], it[1][3]]]}.set{ch_meta}
        ch_sample_sheet.map{it -> [it[0], it[1][4]]}.set{ch_lineage}
    }

    //ch_meta.view()
    //println("dfdfdf");
    //ch_lineage.view()
    PREPARE_ADAPTOR( ch_meta )
    .adaptor
    .set{ adaptor_ch }

    BBMAP_DEDUPE( ch_prepared_fastq )
    .deduplicates
    .set{ deduplicates_ch }
    
    
    BBMAP_REFORMAT( deduplicates_ch )
    .reformated_fastq
    .set{ reformated_ch }
    
    TRIMMOMATIC( 
        reformated_ch.join( adaptor_ch ) 
    )

    PEAR(
        TRIMMOMATIC.out.trimmed_paired
    )
    .merged
    .set{ merged_ch }
    


    TRIMMOMATIC
            .out
            .trimmed_unpaired
            .join(merged_ch)
            .map{ it -> [it[0], [it[1], it[2], it[3]]] }

    CONCATENATE(
        TRIMMOMATIC
            .out
            .trimmed_unpaired
            .join(merged_ch)
            .map{ it -> [it[0], [it[1], it[2], it[3]]] }
        , Channel.value("trimmed_unpaired_concatenated")
    )
    .concatenated
    .set{ unpaired_concatenated_ch }

    TRIMMOMATIC_CLEAN_PE(
        PEAR.out.unmerged
    )
    .trimmed_cleaned_paired
    .set{ prepared_fastq }

    TRIMMOMATIC_CLEAN_SE(
        unpaired_concatenated_ch
    )



    // The step below seems just to concatenate files but not using them any more. Maybe we cancel it.
    CONCATENATE2(
        TRIMMOMATIC_CLEAN_PE
        .out
        .trimmed_cleaned_unpaired
        .join( TRIMMOMATIC_CLEAN_SE
                .out
                .trimmed_cleaned_se
        )
        .map{ it -> [it[0], [it[1], it[2], it[3]]] }
        , Channel.value("trimmed_unpaired_pe_seconcatenated")
    )

    

    BBMAP_FILTER(
        TRIMMOMATIC_CLEAN_PE
        .out
        .trimmed_cleaned_paired
        , ch_reference_genome
    )
    
    CONCATENATE3(
        BBMAP_FILTER
        .out
        .prepared_reads
        .join( CONCATENATE2
                .out
                .concatenated
        )
        .map{ it -> [it[0], [it[1], it[3]]] }
        , Channel.value("trinity_r1_unpaired_concatenated")
    )

    TRINITY(
        BBMAP_FILTER
        .out
        .prepared_reads
        .join( CONCATENATE3
                .out
                .concatenated
        )
        .map{ it -> [it[0], it[3], it[2]] }
    )

    TRINITY_POSTPROCESSING(
        TRINITY
        .out
        .trinity_dir.map{it -> [it[0], "${it[1]}/Trinity.fasta"]}
    )
    
    BLAT(
        TRINITY_POSTPROCESSING
        .out
        .processed
        , ch_blat_db
        , Channel
        .value("to_probes")
        , Channel
        .value(false)
    )

    BLAT2(
        TRINITY_POSTPROCESSING
        .out
        .processed
        , ch_blat_db
        , Channel
        .value("from_probes")
        , Channel
        .value(true)
    )
    
    
    PARSE_BLAT_RESULTS(
        TRINITY_POSTPROCESSING
        .out
        .processed
        .join(BLAT.out.matches)
        .join(BLAT2.out.matches)
    )
    
    MAKE_PRG(
        TRINITY_POSTPROCESSING
        .out
        .processed
        .join(
            PARSE_BLAT_RESULTS.out.matches
        )
        .join(ch_lineage)
    )

    QUALITY_2_ASSEMBLY(
        TRINITY_POSTPROCESSING
        .out
        .processed
        .join(
            MAKE_PRG.out.RGB
        )
        .join(ch_lineage)
    )

    PHYLOGENY_MAKE_ALIGNMENTS(
        MAKE_PRG.out.RGB.map(it -> it[1]).toSortedList()
    )



    MAFFT(
        PHYLOGENY_MAKE_ALIGNMENTS
        .out
        .locus_fasta.toSortedList()
        .flatten().buffer(size: params.batching_size, remainder: true)
    )


    if (params.trimmed){
        GBLOCKS(
            MAFFT.out.aligned
        )
        .trimmed_allignments
        .set{ch_alignment}
    } else{
        ch_alignment = MAFFT.out.aligned
    }
    

    SED( ch_alignment )

    BBMAP_REFORMAT_Z(SED.out.seded)
   
    if (params.tree_method == 'raxml'){
        RAXML(
            BBMAP_REFORMAT_Z.out.reformated
        )

    }else if (params.tree_method == 'phyml'){
        
    }else if (params.tree_method == 'iqtree'){
        
    }


    if (params.tree_method == 'raxml'){
        ch_all_trees = RAXML.out.tree_bipartitions.toSortedList()

    }else if (params.tree_method == 'phyml'){
        
    }else if (params.tree_method == 'iqtree'){
        ch_all_trees = RAXML.out.contree.toSortedList()
    }

    MERGE_TREES(
        ch_all_trees
    )

    ASTER(
        MERGE_TREES.out.merged_trees
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
