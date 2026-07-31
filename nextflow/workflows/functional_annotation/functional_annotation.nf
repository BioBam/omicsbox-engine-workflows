// =============================================================================
// FILE: functional_annotation.nf
// Functional Annotation Pipeline: DIAMOND BLAST + GO Mapping -> BLAST2GO Annotation -> InterProScan + EggNOG -> Merge & Validate -> EC Mapping -> Charts, GO Graph & Gene-Set Export
// =============================================================================

include { LOAD_FASTA                                       } from '../../modules/functional_analysis/load_fasta.nf'
include { DIAMOND_BLAST                                    } from '../../modules/functional_analysis/diamond_blast.nf'
include { BLAST_CHARTS                                     } from '../../modules/functional_analysis/blast_charts.nf'
include { GO_MAPPING                                       } from '../../modules/functional_analysis/go_mapping.nf'
include { GO_MAPPING_CHARTS                                } from '../../modules/functional_analysis/go_mapping_charts.nf'
include { GO_ANNOTATION                                    } from '../../modules/functional_analysis/go_annotation.nf'
include { GO_ANNOTATION_CHARTS as BLAST2GO_ANNOTATION_CHARTS } from '../../modules/functional_analysis/go_annotation_charts.nf'
include { GO_ANNOTATION_CHARTS as FINAL_ANNOTATION_CHARTS  } from '../../modules/functional_analysis/go_annotation_charts.nf'
include { EGGNOG_MAPPER                                    } from '../../modules/metagenomics/eggnog_mapper.nf'
include { INTERPROSCAN                                     } from '../../modules/functional_analysis/ips.nf'
include { IPS_CHARTS                                       } from '../../modules/functional_analysis/ips_charts.nf'
include { COMBINE_PROJECTS                                 } from '../../modules/utilities/combine_projects.nf'
include { MERGE_IPS_GOS_TO_ANNOTATION                      } from '../../modules/functional_analysis/merge_ips_gos_to_annotation.nf'
include { MERGE_EGGNOG_5_GOS                               } from '../../modules/functional_analysis/merge_eggnog_5_gos.nf'
include { VALIDATE_GO_ANNOTATION                           } from '../../modules/functional_analysis/validate_go_annotation.nf'
include { EC_CODE_MAPPING                                  } from '../../modules/functional_analysis/ec_code_mapping.nf'
include { PROJECT_CHARTS                                   } from '../../modules/functional_analysis/project_charts.nf'
include { COMBINED_GO_GRAPH                                } from '../../modules/functional_analysis/combined_go_graph.nf'
include { EXPORT_GENE_SETS                                 } from '../../modules/export_annotations/export_genesets.nf'
include { GO_SLIM                                          } from '../../modules/functional_analysis/go_slim.nf'
include { GO_ANNOTATION_CHARTS as GOSLIM_ANNOTATION_CHARTS } from '../../modules/functional_analysis/go_annotation_charts.nf'

// =============================================================================
workflow {

    main:

    // -------------------------------------------------------------------------
    // Config template export: --dump_config copies this workflow's .config to
    // the launch directory and exits, so the user can edit it and pass it via -c.
    // -------------------------------------------------------------------------
    if (params.dump_config) {
        // 1. Source: this workflow's config template (sibling of the .nf; projectDir = workflow dir under -main-script)
        def sourceConfig = file("${moduleDir}/functional_annotation.config")

        // 2. Target: the current launch directory
        def targetConfig = file("./functional_annotation.config")

        if (sourceConfig.exists()) {
            // 3. Physically copy the file to the user's environment
            sourceConfig.copyTo(targetConfig)

            log.info "========================================================================="
            log.info "  [OK] Configuration template successfully exported!"
            log.info "========================================================================="
            log.info "  File generated at: ./functional_annotation.config"
            log.info ""
            log.info "  Instructions:"
            log.info "  1. Open and modify the parameters in the generated file as needed."
            log.info "  2. Run the actual pipeline pointing to your local configuration using:"
            log.info "     -c functional_annotation.config"
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
    if (!params.input_fasta) {
        exit 1, "ERROR: You must provide a FASTA input file via --input_fasta=/path/to/sequences.fasta"
    }

    // -------------------------------------------------------------------------
    // Channel creation
    // Input is consumed by LOAD_FASTA (for OmicsBox project) and EGGNOG_MAPPER (raw FASTA).
    // -------------------------------------------------------------------------
    def ch_fasta = channel.fromPath(params.input_fasta, checkIfExists: true)

    // Optional custom GO-Slim OBO file (only used with --option=custom). Empty channel -> module omits --i-go-slim-obo-file.
    def ch_goslim_obo = params.goslim.obo_file
        ? channel.fromPath(params.goslim.obo_file, checkIfExists: true).first()
        : channel.value([])

    // -------------------------------------------------------------------------
    // 01 - Load sequences into OmicsBox project
    // -------------------------------------------------------------------------
    LOAD_FASTA(ch_fasta)

    // -------------------------------------------------------------------------
    // 02-03 - Sequence homology search & GO mapping
    // DIAMOND_BLAST and GO_MAPPING both consume the same LOAD_FASTA project
    // and run in parallel, branching the workflow into two annotation streams
    // -------------------------------------------------------------------------
    DIAMOND_BLAST(LOAD_FASTA.out.fasta_project)
    BLAST_CHARTS(DIAMOND_BLAST.out.blasted_project)
    GO_MAPPING(DIAMOND_BLAST.out.blasted_project)
    GO_MAPPING_CHARTS(GO_MAPPING.out.mapped_project)

    // -------------------------------------------------------------------------
    // 04 - Initial GO annotation via BLAST2GO
    // -------------------------------------------------------------------------
    GO_ANNOTATION(GO_MAPPING.out.mapped_project)
    BLAST2GO_ANNOTATION_CHARTS(GO_ANNOTATION.out.annotated_project)

    // -------------------------------------------------------------------------
    // 05-06 - Parallel domain & orthology prediction
    // INTERPROSCAN consumes the LOAD_FASTA project (same as DIAMOND_BLAST);
    // EGGNOG_MAPPER consumes the raw FASTA directly.
    // -------------------------------------------------------------------------
    EGGNOG_MAPPER(ch_fasta)
    INTERPROSCAN(LOAD_FASTA.out.fasta_project)
    IPS_CHARTS(INTERPROSCAN.out.ips_project)

    // -------------------------------------------------------------------------
    // 07-09 - Multi-branch project consolidation (GO annotation + InterProScan + EggNOG)
    // -------------------------------------------------------------------------
    COMBINE_PROJECTS(GO_ANNOTATION.out.annotated_project, INTERPROSCAN.out.ips_project)
    MERGE_IPS_GOS_TO_ANNOTATION(COMBINE_PROJECTS.out.combined_project)
    MERGE_EGGNOG_5_GOS(MERGE_IPS_GOS_TO_ANNOTATION.out.merged_project, EGGNOG_MAPPER.out.eggnog_project)

    // -------------------------------------------------------------------------
    // 10-13 - Final curation, enzyme mapping & comprehensive reporting
    // All downstream processes consume the unified, fully-annotated master project
    // -------------------------------------------------------------------------
    VALIDATE_GO_ANNOTATION(MERGE_EGGNOG_5_GOS.out.merged_project)
    EC_CODE_MAPPING(VALIDATE_GO_ANNOTATION.out.validated_project)
    FINAL_ANNOTATION_CHARTS(EC_CODE_MAPPING.out.ec_mapped_project)
    PROJECT_CHARTS(EC_CODE_MAPPING.out.ec_mapped_project)
    COMBINED_GO_GRAPH(EC_CODE_MAPPING.out.ec_mapped_project)
    EXPORT_GENE_SETS(EC_CODE_MAPPING.out.ec_mapped_project)
    GO_SLIM(EC_CODE_MAPPING.out.ec_mapped_project, ch_goslim_obo)
    GOSLIM_ANNOTATION_CHARTS(GO_SLIM.out.project)
}
