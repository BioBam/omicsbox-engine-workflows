// =============================================================================
// FILE: prokaryotic_genome_analysis.nf
// Prokaryotic Genome Analysis Pipeline: Preprocessing -> Assembly -> Gene Finding -> Functional Annotation
// =============================================================================

include { FASTQC as FASTQC_RAW   } from '../../modules/general_tools/fastqc.nf'
include { TRIMMOMATIC            } from '../../modules/general_tools/trimmomatic.nf'
include { FASTQC as FASTQC_POST  } from '../../modules/general_tools/fastqc.nf'
include { SPADES                 } from '../../modules/genome_analysis/spades.nf'
include { QUAST                  } from '../../modules/genome_analysis/quast.nf'
include { BUSCO                  } from '../../modules/genome_analysis/busco.nf'
include { GLIMMER                } from '../../modules/genome_analysis/glimmer.nf'
include { DIAMOND_BLAST          } from '../../modules/functional_analysis/diamond_blast.nf'

// =============================================================================
workflow {

    main:

    // -------------------------------------------------------------------------
    // Config template export: --dump_config copies this workflow's .config to
    // the launch directory and exits, so the user can edit it and pass it via -c.
    // -------------------------------------------------------------------------
    if (params.dump_config) {
        // 1. Source: this workflow's config template (sibling of the .nf; projectDir = workflow dir under -main-script)
        def sourceConfig = file("${moduleDir}/prokaryotic_genome_analysis.config")

        // 2. Target: the current launch directory
        def targetConfig = file("./prokaryotic_genome_analysis.config")

        if (sourceConfig.exists()) {
            // 3. Physically copy the file to the user's environment
            sourceConfig.copyTo(targetConfig)

            log.info "========================================================================="
            log.info "  [OK] Configuration template successfully exported!"
            log.info "========================================================================="
            log.info "  File generated at: ./prokaryotic_genome_analysis.config"
            log.info ""
            log.info "  Instructions:"
            log.info "  1. Open and modify the parameters in the generated file as needed."
            log.info "  2. Run the actual pipeline pointing to your local configuration using:"
            log.info "     -c prokaryotic_genome_analysis.config"
            log.info "========================================================================="
        } else {
            log.error "  [ERROR] Could not find the internal template at: ${sourceConfig}"
        }

        // 4. Stop Nextflow safely with exit code 0 (success)
        exit 0
    }


    // -------------------------------------------------------------------------
    // Safety checks - all 4 critical inputs
    // -------------------------------------------------------------------------
    if (!params.input_paired_end && !params.input_single_end) {
        exit 1, "ERROR: You must provide reads via --input_paired_end or --input_single_end."
    }
    if (params.input_paired_end && params.input_single_end) {
        exit 1, "ERROR: Provide either --input_paired_end or --input_single_end, not both."
    }

    // -------------------------------------------------------------------------
    // STRICT VALIDATION: SPAdes Paired-End Library Type (Fail Fast)
    // -------------------------------------------------------------------------
    if (params.input_paired_end) {
        def valid_pe_types = ['paired-end-fr', 'paired-end-rf', 'paired-end-ff', 'hq-mate-pair-fr', 'hq-mate-pair-rf', 'hq-mate-pair-ff', 'nxmate']
        if (!params.spades.paired_end_library_type) {
            exit 1, "ERROR: When using paired-end reads, you must explicitly define params.spades.paired_end_library_type in the config file. Valid options: ${valid_pe_types.join(', ')}"
        } else if (!valid_pe_types.contains(params.spades.paired_end_library_type)) {
            exit 1, "ERROR: Invalid params.spades.paired_end_library_type '${params.spades.paired_end_library_type}'. Valid options: ${valid_pe_types.join(', ')}"
        }
    }

    // -------------------------------------------------------------------------
    // Channel creation
    // ARCHITECTURAL NOTE: .collect() gathers all reads into a single List so that
    // only ONE OmicsBox task is spawned. OmicsBox parallelises internally over samples.
    // -------------------------------------------------------------------------
    def ch_reads = params.input_single_end
        ? channel.fromPath(params.input_single_end, checkIfExists: true).collect()
        : channel.fromPath(params.input_paired_end, checkIfExists: true).collect()

    def ch_reference = channel.fromPath(params.quast.reference_genome, checkIfExists: true).first()

    // Optional file inputs - channel.value([]) acts as a safe empty placeholder
    def ch_icm_model = params.glimmer.icm_model
        ? channel.fromPath(params.glimmer.icm_model, checkIfExists: true)
        : channel.value([])

    def ch_trimmomatic_adapters = params.trimmomatic.adapters
        ? channel.fromPath(params.trimmomatic.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_adapters = params.fastqc.adapters
        ? channel.fromPath(params.fastqc.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_contaminants = params.fastqc.contaminants
        ? channel.fromPath(params.fastqc.contaminants, checkIfExists: true)
        : channel.value([])

    def ch_spades_opt_mp_fr = params.spades.opt_mp_fr
        ? channel.fromPath(params.spades.opt_mp_fr, checkIfExists: true).collect()
        : channel.value([])

    def ch_spades_opt_mp_rf = params.spades.opt_mp_rf
        ? channel.fromPath(params.spades.opt_mp_rf, checkIfExists: true).collect()
        : channel.value([])

    def ch_spades_opt_mp_ff = params.spades.opt_mp_ff
        ? channel.fromPath(params.spades.opt_mp_ff, checkIfExists: true).collect()
        : channel.value([])

    def ch_spades_sanger = params.spades.sanger
        ? channel.fromPath(params.spades.sanger, checkIfExists: true).collect()
        : channel.value([])

    def ch_spades_pacbio = params.spades.pacbio
        ? channel.fromPath(params.spades.pacbio, checkIfExists: true).collect()
        : channel.value([])

    def ch_spades_nanopore = params.spades.nanopore
        ? channel.fromPath(params.spades.nanopore, checkIfExists: true).collect()
        : channel.value([])

    def ch_spades_trusted_contigs = params.spades.trusted_contigs
        ? channel.fromPath(params.spades.trusted_contigs, checkIfExists: true).collect()
        : channel.value([])

    def ch_spades_untrusted_contigs = params.spades.untrusted_contigs
        ? channel.fromPath(params.spades.untrusted_contigs, checkIfExists: true).collect()
        : channel.value([])

    // -------------------------------------------------------------------------
    // 01 - Raw quality assessment (isolated: outputs are NOT connected downstream)
    // -------------------------------------------------------------------------
    FASTQC_RAW(ch_reads, ch_fastqc_adapters, ch_fastqc_contaminants)

    // -------------------------------------------------------------------------
    // 02 - Preprocessing & adapter removal
    // -------------------------------------------------------------------------
    TRIMMOMATIC(ch_reads, ch_trimmomatic_adapters)

    // -------------------------------------------------------------------------
    // 03 - Quality assessment (post-trimming)
    // -------------------------------------------------------------------------
    FASTQC_POST(TRIMMOMATIC.out.trimmed_reads, ch_fastqc_adapters, ch_fastqc_contaminants)

    // -------------------------------------------------------------------------
    // 04 - De novo genome assembly
    // SPADES main input is TRIMMED reads from Trimmomatic, which may be biologically
    // single-end or paired-end (FR/RF/FF/HQ-MP/NxMate orientation set via config).
    // Optional channels (8 total) bypass Trimmomatic and are fed directly to SPAdes via
    // dynamic flag injection (--use-mp-optional-data and --use-data-for-hybrid-assembly
    // are injected only if corresponding inputs are provided; safe empty placeholder []).
    // -------------------------------------------------------------------------
    SPADES(
        TRIMMOMATIC.out.trimmed_reads,
        ch_spades_opt_mp_fr,
        ch_spades_opt_mp_rf,
        ch_spades_opt_mp_ff,
        ch_spades_sanger,
        ch_spades_pacbio,
        ch_spades_nanopore,
        ch_spades_trusted_contigs,
        ch_spades_untrusted_contigs
    )

    // -------------------------------------------------------------------------
    // 05-06 - Parallel assembly evaluation
    // Both QUAST and BUSCO take the assembly FASTA from SPADES.
    // -------------------------------------------------------------------------
    QUAST(SPADES.out.scaffolds, ch_reference)
    BUSCO(SPADES.out.scaffolds)

    // -------------------------------------------------------------------------
    // 07 - Prokaryotic gene finding
    // CRITICAL: GLIMMER requires ONE input:
    //   - Input 1: Assembly FASTA from SPADES
    // OPTIONAL: Provide an existing ICM model for species-specific prediction.
    //   If no ICM model is provided, Glimmer will create a new model.
    // -------------------------------------------------------------------------
    GLIMMER(SPADES.out.scaffolds, ch_icm_model)

    // -------------------------------------------------------------------------
    // 08 - Functional annotation of predicted genes
    // -------------------------------------------------------------------------
    DIAMOND_BLAST(GLIMMER.out.project)

}
