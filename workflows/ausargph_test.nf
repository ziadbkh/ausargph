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
def checkPathParamList = [ params.input, params.reference_genome ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
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

include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { TESTING } from '../modules/local/testing'

include { PREPARE_ADAPTOR } from '../modules/local/prepare_adaptor'
include { PREPARE_SAMPLESHEET } from '../modules/local/prepare_samplesheet'
include { BBMAP_DEDUPE } from '../modules/local/bbmap_dedupe'
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
    
    Channel
        .fromPath(params.input + '*.fasta.aln').set{MAFFT}

    GBLOCKS(
            MAFFT
        )
        .trimmed_allignments
        .set{ch_alignment}
       

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
