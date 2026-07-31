// =============================================================================
// FILE: transcript_level_analysis.nf
// Transcript-Level RNA-Seq Analysis Pipeline: Preprocessing -> Quantification (RSEM) -> PCA & differential expression (edgeR)
// =============================================================================

include { FASTQC as FASTQC_RAW   } from '../../modules/general_tools/fastqc.nf'
include { TRIMMOMATIC            } from '../../modules/general_tools/trimmomatic.nf'
include { FASTQC as FASTQC_POST  } from '../../modules/general_tools/fastqc.nf'
include { RSEM                   } from '../../modules/transcriptomics/rsem.nf'
include { COUNTS_PCA             } from '../../modules/transcriptomics/counts_pca.nf'
include { EDGER                  } from '../../modules/transcriptomics/edger.nf'

// =============================================================================
workflow {

    main:

    // -------------------------------------------------------------------------
    // Config template export: --dump_config copies this workflow's .config to
    // the launch directory and exits, so the user can edit it and pass it via -c.
    // -------------------------------------------------------------------------
    if (params.dump_config) {
        // 1. Source: this workflow's config template (sibling of the .nf; projectDir = workflow dir under -main-script)
        def sourceConfig = file("${moduleDir}/transcript_level_analysis.config")

        // 2. Target: the current launch directory
        def targetConfig = file("./transcript_level_analysis.config")

        if (sourceConfig.exists()) {
            // 3. Physically copy the file to the user's environment
            sourceConfig.copyTo(targetConfig)

            log.info "========================================================================="
            log.info "  [OK] Configuration template successfully exported!"
            log.info "========================================================================="
            log.info "  File generated at: ./transcript_level_analysis.config"
            log.info ""
            log.info "  Instructions:"
            log.info "  1. Open and modify the parameters in the generated file as needed."
            log.info "  2. Run the actual pipeline pointing to your local configuration using:"
            log.info "     -c transcript_level_analysis.config"
            log.info "========================================================================="
        } else {
            log.error "  [ERROR] Could not find the internal template at: ${sourceConfig}"
        }

        // 4. Stop Nextflow safely with exit code 0 (success)
        exit 0
    }


    // -------------------------------------------------------------------------
    // Safety checks
    // -------------------------------------------------------------------------
    if (!params.input_paired_end && !params.input_single_end) {
        exit 1, "ERROR: You must provide reads via --input_paired_end or --input_single_end."
    }
    if (params.input_paired_end && params.input_single_end) {
        exit 1, "ERROR: Provide either --input_paired_end or --input_single_end, not both."
    }
    if (!params.input_fasta) {
        exit 1, "ERROR: You must provide a reference transcriptome FASTA via --input_fasta."
    }
    if (!params.experimental_design) {
        exit 1, "ERROR: You must provide an experimental design file via --experimental_design."
    }
    // Gene-level estimates are the sum of each gene's isoform estimates, so RSEM needs the map that
    // says which isoform belongs to which gene. Without it every reference sequence is its own gene
    // and the 'gene' table comes back identical to the transcript one - a silent no-op, so stop here.
    if (params.rsem.gene_level && !params.rsem.gene_trans_map) {
        exit 1, "ERROR: rsem.gene_level = true requires rsem.gene_trans_map, the transcript-to-gene map RSEM groups isoforms by."
    }

    // -------------------------------------------------------------------------
    // Channel creation
    // ARCHITECTURAL NOTE: .collect() gathers all reads into a single List so that
    // only ONE OmicsBox task is spawned. OmicsBox parallelises internally over samples.
    // -------------------------------------------------------------------------
    def ch_reads = params.input_single_end
        ? channel.fromPath(params.input_single_end, checkIfExists: true).collect()
        : channel.fromPath(params.input_paired_end, checkIfExists: true).collect()

    def ch_fasta = channel.fromPath(params.input_fasta, checkIfExists: true).first()
    def ch_design = channel.fromPath(params.experimental_design, checkIfExists: true).first()

    // Optional file inputs - channel.value([]) acts as a safe empty placeholder
    def ch_trimmomatic_adapters = params.trimmomatic.adapters
        ? channel.fromPath(params.trimmomatic.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_adapters = params.fastqc.adapters
        ? channel.fromPath(params.fastqc.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_contaminants = params.fastqc.contaminants
        ? channel.fromPath(params.fastqc.contaminants, checkIfExists: true)
        : channel.value([])

     def ch_genes_trans_map = params.rsem.gene_trans_map
        ? channel.fromPath(params.rsem.gene_trans_map, checkIfExists: true).first()
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
    // 04 - Transcript quantification
    // CRITICAL: RSEM requires TWO inputs:
    //   - Input 1: Trimmed FASTQ reads from TRIMMOMATIC
    //   - Input 2: Reference transcriptome FASTA file
    // -------------------------------------------------------------------------
    RSEM(TRIMMOMATIC.out.trimmed_reads, ch_fasta, ch_genes_trans_map)

    // -------------------------------------------------------------------------
    // 05-06 - Parallel statistical analysis
    // Both PCA and edgeR consume the count table from RSEM and the experimental design.
    // Gene-level mode swaps WHICH table they read: RSEM's gene estimates are the sum of each gene's
    // isoform estimates, so the statistics then test genes instead of individual transcripts.
    // -------------------------------------------------------------------------
    def ch_counts = params.rsem.gene_level
        ? RSEM.out.count_table_genes
        : RSEM.out.count_table_transcripts

    // The design file is MANDATORY for edgeR - it is the model - but for the PCA it is only
    // colouring. Feeding the same mandatory channel to both left the PCA unable to express
    // "design available, but plot without it": counts_pca pairs --design=true with the file,
    // so the file's presence alone forced design-aware plotting. params.counts_pca.use_design
    // gives the optional consumer its own switch, wired the same way as params.rsem.gene_level.
    def ch_pca_design = (params.counts_pca?.use_design == false)
        ? channel.value([])
        : ch_design

    COUNTS_PCA(ch_counts, ch_pca_design)
    EDGER(ch_counts, ch_design)

}
