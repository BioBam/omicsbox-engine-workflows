// =============================================================================
// FILE: eukaryotic_genome_analysis.nf
// Eukaryotic Genome Analysis Pipeline: Preprocessing -> Assembly -> Annotation -> Functional Analysis
// =============================================================================

include { FASTQC as FASTQC_RAW   } from '../../modules/general_tools/fastqc.nf'
include { TRIMMOMATIC            } from '../../modules/general_tools/trimmomatic.nf'
include { FASTQC as FASTQC_POST  } from '../../modules/general_tools/fastqc.nf'
include { ABYSS                  } from '../../modules/genome_analysis/abyss.nf'
include { QUAST                  } from '../../modules/genome_analysis/quast.nf'
include { BUSCO                  } from '../../modules/genome_analysis/busco.nf'
include { REPEATMASKER           } from '../../modules/genome_analysis/repeatmasker.nf'
include { AUGUSTUS               } from '../../modules/genome_analysis/augustus.nf'
include { DIAMOND_BLAST          } from '../../modules/functional_analysis/diamond_blast.nf'
include { INTERPROSCAN           } from '../../modules/functional_analysis/ips.nf'
include { COMBINE_PROJECTS       } from '../../modules/utilities/combine_projects.nf'
include { GO_MAPPING             } from '../../modules/functional_analysis/go_mapping.nf'
include { GO_ANNOTATION          } from '../../modules/functional_analysis/go_annotation.nf'
include { MERGE_IPS_GOS_TO_ANNOTATION } from '../../modules/functional_analysis/merge_ips_gos_to_annotation.nf'

// =============================================================================
workflow {

    main:

    // -------------------------------------------------------------------------
    // Config template export: --dump_config copies this workflow's .config to
    // the launch directory and exits, so the user can edit it and pass it via -c.
    // -------------------------------------------------------------------------
    if (params.dump_config) {
        // 1. Source: this workflow's config template (sibling of the .nf; projectDir = workflow dir under -main-script)
        def sourceConfig = file("${moduleDir}/eukaryotic_genome_analysis.config")

        // 2. Target: the current launch directory
        def targetConfig = file("./eukaryotic_genome_analysis.config")

        if (sourceConfig.exists()) {
            // 3. Physically copy the file to the user's environment
            sourceConfig.copyTo(targetConfig)

            log.info "========================================================================="
            log.info "  [OK] Configuration template successfully exported!"
            log.info "========================================================================="
            log.info "  File generated at: ./eukaryotic_genome_analysis.config"
            log.info ""
            log.info "  Instructions:"
            log.info "  1. Open and modify the parameters in the generated file as needed."
            log.info "  2. Run the actual pipeline pointing to your local configuration using:"
            log.info "     -c eukaryotic_genome_analysis.config"
            log.info "========================================================================="
        } else {
            log.error "  [ERROR] Could not find the internal template at: ${sourceConfig}"
        }

        // 4. Stop Nextflow safely with exit code 0 (success)
        exit 0
    }


    // -------------------------------------------------------------------------
    // Safety checks - critical inputs for eukaryotic pipeline
    // -------------------------------------------------------------------------
    if (!params.input_paired_end && !params.input_single_end) {
        exit 1, "ERROR: You must provide reads via --input_paired_end or --input_single_end."
    }
    if (params.input_paired_end && params.input_single_end) {
        exit 1, "ERROR: Provide either --input_paired_end or --input_single_end, not both."
    }
    // -------------------------------------------------------------------------
    // STRICT VALIDATION: RepeatMasker File Logic
    // -------------------------------------------------------------------------
    def rm_engine = params.repeatmasker.search_engine
    def rm_db_type = params.repeatmasker.database_type
    def rm_db_file = params.repeatmasker.database_file

    if (rm_engine == 'rmblast' && (rm_db_type == 'repbase' || rm_db_type == 'custom')) {
        if (!rm_db_file) {
            exit 1, "ERROR: RepeatMasker requires a database file via params.repeatmasker.database_file when search_engine is 'rmblast' and database_type is '${rm_db_type}'."
        }
    }

    // -------------------------------------------------------------------------
    // STRICT VALIDATION: Augustus Gene Finding Mode
    // -------------------------------------------------------------------------
    if (params.augustus.gene_finding_mode == 'ee') {
        def has_any_hint = params.augustus.est_hints || params.augustus.protein_hints || params.augustus.isoseq_hints || params.augustus.rna_seq_se_hints || params.augustus.rna_seq_pe_hints
        if (!has_any_hint) {
            exit 1, "ERROR: When Augustus gene_finding_mode is 'ee' (Extrinsic Evidence), you must provide at least one hint file (est_hints, protein_hints, isoseq_hints, rna_seq_se_hints, or rna_seq_pe_hints)."
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

    def ch_repeat_db = params.repeatmasker.database_file
        ? channel.fromPath(params.repeatmasker.database_file, checkIfExists: true)
        : channel.value([])

    def ch_quast_ref = channel.fromPath(params.quast.reference_genome, checkIfExists: true).first()

    def ch_trimmomatic_adapters = params.trimmomatic.adapters
        ? channel.fromPath(params.trimmomatic.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_adapters = params.fastqc.adapters
        ? channel.fromPath(params.fastqc.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_contaminants = params.fastqc.contaminants
        ? channel.fromPath(params.fastqc.contaminants, checkIfExists: true)
        : channel.value([])

    def ch_abyss_linked = params.abyss.linked_reads
        ? channel.fromPath(params.abyss.linked_reads, checkIfExists: true).collect()
        : channel.value([])

    def ch_abyss_add_pe = params.abyss.additional_pe
        ? channel.fromPath(params.abyss.additional_pe, checkIfExists: true).collect()
        : channel.value([])

    def ch_abyss_mp = params.abyss.mate_pair
        ? channel.fromPath(params.abyss.mate_pair, checkIfExists: true).collect()
        : channel.value([])

    def ch_abyss_long = params.abyss.long_sequences
        ? channel.fromPath(params.abyss.long_sequences, checkIfExists: true).collect()
        : channel.value([])

    def ch_aug_est = params.augustus.est_hints
        ? channel.fromPath(params.augustus.est_hints, checkIfExists: true).collect()
        : channel.value([])

    def ch_aug_protein = params.augustus.protein_hints
        ? channel.fromPath(params.augustus.protein_hints, checkIfExists: true).collect()
        : channel.value([])

    def ch_aug_isoseq = params.augustus.isoseq_hints
        ? channel.fromPath(params.augustus.isoseq_hints, checkIfExists: true).collect()
        : channel.value([])

    def ch_aug_rna_se = params.augustus.rna_seq_se_hints
        ? channel.fromPath(params.augustus.rna_seq_se_hints, checkIfExists: true).collect()
        : channel.value([])

    def ch_aug_rna_ds = params.augustus.rna_seq_pe_hints
        ? channel.fromPath(params.augustus.rna_seq_pe_hints, checkIfExists: true).collect()
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
    // 04 - De novo eukaryotic genome assembly using ABySS
    // CRITICAL: ABySS takes trimmed reads from Trimmomatic.
    // -------------------------------------------------------------------------
    ABYSS(
        TRIMMOMATIC.out.trimmed_reads,
        ch_abyss_linked,
        ch_abyss_add_pe,
        ch_abyss_mp,
        ch_abyss_long
    )

    // -------------------------------------------------------------------------
    // 05-06 - Parallel assembly evaluation
    // Both QUAST and BUSCO take the scaffolds FASTA from ABySS.
    // -------------------------------------------------------------------------
    QUAST(ABYSS.out.scaffolds, ch_quast_ref)
    BUSCO(ABYSS.out.scaffolds)

    // -------------------------------------------------------------------------
    // 07 - Repeat masking for eukaryotic genome
    // CRITICAL: RepeatMasker takes ABySS assembly scaffolds.
    // -------------------------------------------------------------------------
    REPEATMASKER(ABYSS.out.scaffolds, ch_repeat_db)

    // -------------------------------------------------------------------------
    // 08 - Eukaryotic gene finding with AUGUSTUS
    // CRITICAL: AUGUSTUS takes soft-masked FASTA from RepeatMasker.
    // -------------------------------------------------------------------------
    AUGUSTUS(
        REPEATMASKER.out.masked_fasta,
        ch_aug_est,
        ch_aug_protein,
        ch_aug_isoseq,
        ch_aug_rna_se,
        ch_aug_rna_ds
    )

    // -------------------------------------------------------------------------
    // 09-10 - Parallel functional annotation branching
    // Both DIAMOND_BLAST and INTERPROSCAN run on Augustus project output.
    // -------------------------------------------------------------------------
    DIAMOND_BLAST(AUGUSTUS.out.protein_project)
    INTERPROSCAN(AUGUSTUS.out.protein_project)

    // -------------------------------------------------------------------------
    // 11 - Combine Diamond and InterProScan annotations
    // CRITICAL: Takes BOTH the Diamond and InterProScan projects and merges
    // them into a single unified project.
    // -------------------------------------------------------------------------
    COMBINE_PROJECTS(DIAMOND_BLAST.out.blasted_project, INTERPROSCAN.out.ips_project)

    // -------------------------------------------------------------------------
    // 12 - Gene Ontology mapping
    // -------------------------------------------------------------------------
    GO_MAPPING(COMBINE_PROJECTS.out.combined_project)

    // -------------------------------------------------------------------------
    // 13 - BLAST2GO functional annotation
    // -------------------------------------------------------------------------
    GO_ANNOTATION(GO_MAPPING.out.mapped_project)

    // -------------------------------------------------------------------------
    // 14 - Final merge: InterProScan + GO-annotated genes
    // -------------------------------------------------------------------------
    MERGE_IPS_GOS_TO_ANNOTATION(GO_ANNOTATION.out.annotated_project)

}
