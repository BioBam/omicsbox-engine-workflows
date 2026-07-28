// =============================================================================
// FILE: long_reads_prokaryotic_genome_analysis.nf
// Long-Read Prokaryotic Genome Analysis Pipeline: QC -> Assembly -> Polish -> Gene Finding -> Functional Analysis
// =============================================================================

include { LONGQC                  } from '../../modules/general_tools/longqc.nf'
include { FLYE                    } from '../../modules/genome_analysis/flye.nf'
include { QUAST                   } from '../../modules/genome_analysis/quast.nf'
include { BWA                     } from '../../modules/genome_analysis/bwa.nf'
include { PILON                   } from '../../modules/genome_analysis/pilon.nf'
include { BUSCO                   } from '../../modules/genome_analysis/busco.nf'
include { GLIMMER                 } from '../../modules/genome_analysis/glimmer.nf'
include { DIAMOND_BLAST           } from '../../modules/functional_analysis/diamond_blast.nf'
include { INTERPROSCAN            } from '../../modules/functional_analysis/ips.nf'
include { COMBINE_PROJECTS        } from '../../modules/utilities/combine_projects.nf'
include { GO_MAPPING              } from '../../modules/functional_analysis/go_mapping.nf'
include { GO_ANNOTATION           } from '../../modules/functional_analysis/go_annotation.nf'
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
        def sourceConfig = file("${moduleDir}/long_reads_prokaryotic_genome_analysis.config")

        // 2. Target: the current launch directory
        def targetConfig = file("./long_reads_prokaryotic_genome_analysis.config")

        if (sourceConfig.exists()) {
            // 3. Physically copy the file to the user's environment
            sourceConfig.copyTo(targetConfig)

            log.info "========================================================================="
            log.info "  [OK] Configuration template successfully exported!"
            log.info "========================================================================="
            log.info "  File generated at: ./long_reads_prokaryotic_genome_analysis.config"
            log.info ""
            log.info "  Instructions:"
            log.info "  1. Open and modify the parameters in the generated file as needed."
            log.info "  2. Run the actual pipeline pointing to your local configuration using:"
            log.info "     -c long_reads_prokaryotic_genome_analysis.config"
            log.info "========================================================================="
        } else {
            log.error "  [ERROR] Could not find the internal template at: ${sourceConfig}"
        }

        // 4. Stop Nextflow safely with exit code 0 (success)
        exit 0
    }


    // -------------------------------------------------------------------------
    // Safety checks - critical inputs for long-read prokaryotic pipeline
    // -------------------------------------------------------------------------
    if (!params.input_long_reads) {
        exit 1, "ERROR: You must provide long reads via --input_long_reads."
    }

    if (!params.flye.library_type) {
        exit 1, "ERROR: You must provide Flye library type via --flye.library_type (options: pacbio_raw, pacbio_corr, pacbio_hifi, nano_raw, nano_corr)."
    }

    if (!['pacbio_raw', 'pacbio_corr', 'pacbio_hifi', 'nano_raw', 'nano_corr'].contains(params.flye.library_type)) {
        exit 1, "ERROR: Flye library_type must be one of: pacbio_raw, pacbio_corr, pacbio_hifi, nano_raw, nano_corr. Got: ${params.flye.library_type}"
    }

    if (!params.input_single_end && !params.input_paired_end) {
        exit 1, "ERROR: You must provide short reads via --input_single_end or --input_paired_end for BWA polishing."
    }

    if (params.input_single_end && params.input_paired_end) {
        exit 1, "ERROR: Provide either --input_single_end or --input_paired_end, not both."
    }

    // -------------------------------------------------------------------------
    // STRICT VALIDATION: QUAST Reference Genome
    // QUAST always passes --i-reference, so the file is required even though it
    // feeds a single step. Without this guard, fromPath(null) aborts the run with
    // "Missing `fromPath` parameter", which names neither the step nor the param.
    // -------------------------------------------------------------------------
    if (!params.quast.reference_genome) {
        exit 1, "ERROR: QUAST requires a reference genome via params.quast.reference_genome."
    }

    // -------------------------------------------------------------------------
    // Channel creation
    // ARCHITECTURAL NOTE: .collect() gathers all reads into a single List so that
    // only ONE OmicsBox task is spawned. OmicsBox parallelises internally over samples.
    // -------------------------------------------------------------------------
    def ch_long_reads = channel.fromPath(params.input_long_reads, checkIfExists: true).collect()

    def ch_short_reads = params.input_single_end
        ? channel.fromPath(params.input_single_end, checkIfExists: true).collect()
        : channel.fromPath(params.input_paired_end, checkIfExists: true).collect()

    def ch_quast_ref = channel.fromPath(params.quast.reference_genome, checkIfExists: true).first()

    def ch_glimmer_icm = params.glimmer.icm_model
        ? channel.fromPath(params.glimmer.icm_model, checkIfExists: true)
        : channel.value([])

    // -------------------------------------------------------------------------
    // 01 - Long-read quality control & trimming
    // -------------------------------------------------------------------------
    LONGQC(ch_long_reads)

    // -------------------------------------------------------------------------
    // 02 - De novo long-read assembly using Flye
    // Takes trimmed reads from LONGQC.
    // -------------------------------------------------------------------------
    FLYE(LONGQC.out.trimmed_reads)

    // -------------------------------------------------------------------------
    // 03 - Assembly quality assessment (QUAST)
    // Evaluates the unpolished Flye assembly.
    // -------------------------------------------------------------------------
    QUAST(FLYE.out.assembly, ch_quast_ref)

    // -------------------------------------------------------------------------
    // 04 - Short-read alignment to long-read assembly (BWA)
    // Maps short reads to Flye assembly for polishing.
    // -------------------------------------------------------------------------
    BWA(FLYE.out.assembly, ch_short_reads)

    // -------------------------------------------------------------------------
    // 05 - Hybrid assembly polishing (PILON)
    // Polishes Flye assembly using short-read alignments from BWA.
    // -------------------------------------------------------------------------
    PILON(FLYE.out.assembly, BWA.out.sorted_bam)

    // -------------------------------------------------------------------------
    // 06 - Assembly completeness assessment (BUSCO)
    // Evaluates the polished assembly.
    // -------------------------------------------------------------------------
    BUSCO(PILON.out.polished_assembly)

    // -------------------------------------------------------------------------
    // 07 - Prokaryotic gene finding with GLIMMER
    // Takes the polished assembly from Pilon.
    // -------------------------------------------------------------------------
    GLIMMER(PILON.out.polished_assembly, ch_glimmer_icm)

    // -------------------------------------------------------------------------
    // 08-09 - Parallel functional annotation branching
    // Both DIAMOND_BLAST and INTERPROSCAN run on GLIMMER project output.
    // -------------------------------------------------------------------------
    DIAMOND_BLAST(GLIMMER.out.project)
    INTERPROSCAN(GLIMMER.out.project)

    // -------------------------------------------------------------------------
    // 10 - Combine Diamond and InterProScan annotations
    // -------------------------------------------------------------------------
    COMBINE_PROJECTS(DIAMOND_BLAST.out.blasted_project, INTERPROSCAN.out.ips_project)

    // -------------------------------------------------------------------------
    // 11 - Gene Ontology mapping
    // -------------------------------------------------------------------------
    GO_MAPPING(COMBINE_PROJECTS.out.combined_project)

    // -------------------------------------------------------------------------
    // 12 - BLAST2GO functional annotation
    // -------------------------------------------------------------------------
    GO_ANNOTATION(GO_MAPPING.out.mapped_project)

    // -------------------------------------------------------------------------
    // 13 - Final merge: InterProScan + GO-annotated genes
    // -------------------------------------------------------------------------
    MERGE_IPS_GOS_TO_ANNOTATION(GO_ANNOTATION.out.annotated_project)

}
