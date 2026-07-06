// =============================================================================
// FILE: de_novo_transcriptome_characterization.nf
nextflow.enable.dsl=2

include { FASTQC as FASTQC_RAW    } from '../../modules/general_tools/fastqc.nf'
include { FASTQC as FASTQC_POST   } from '../../modules/general_tools/fastqc.nf'
include { TRIMMOMATIC             } from '../../modules/general_tools/trimmomatic.nf'
include { TRINITY                 } from '../../modules/transcriptomics/trinity.nf'
include { CDHIT                   } from '../../modules/transcriptomics/cdhit.nf'
include { BUSCO                   } from '../../modules/genome_analysis/busco.nf'
include { TRANSDECODER            } from '../../modules/transcriptomics/transdecoder.nf'
include { LOAD_FASTA              } from '../../modules/functional_analysis/load_fasta.nf'
include { DIAMOND_BLAST           } from '../../modules/functional_analysis/diamond_blast.nf'
include { BLAST_CHARTS            } from '../../modules/functional_analysis/blast_charts.nf'
include { INTERPROSCAN            } from '../../modules/functional_analysis/ips.nf'
include { IPS_CHARTS               } from '../../modules/functional_analysis/ips_charts.nf'
include { EGGNOG_MAPPER           } from '../../modules/metagenomics/eggnog_mapper.nf'
include { COMBINE_PROJECTS        } from '../../modules/utilities/combine_projects.nf'
include { MERGE_EGGNOG_5_GOS      } from '../../modules/functional_analysis/merge_eggnog_5_gos.nf'

// =============================================================================
workflow {

    main:

    // -------------------------------------------------------------------------
    // Safety checks
    // -------------------------------------------------------------------------
    if (!params.input_paired_end && !params.input_single_end) {
        exit 1, "ERROR: You must provide reads via --input_paired_end or --input_single_end."
    }
    if (params.input_paired_end && params.input_single_end) {
        exit 1, "ERROR: Provide either --input_paired_end or --input_single_end, not both."
    }

    // -------------------------------------------------------------------------
    // Channel creation
    // ARCHITECTURAL NOTE: .collect() gathers all reads into a single List so that
    // only ONE OmicsBox task is spawned. OmicsBox parallelises internally over samples.
    // -------------------------------------------------------------------------
    def ch_reads = params.input_single_end
        ? channel.fromPath(params.input_single_end, checkIfExists: true).collect()
        : channel.fromPath(params.input_paired_end, checkIfExists: true).collect()

    // Optional file inputs — channel.value([]) acts as a safe empty placeholder
    def ch_trimmomatic_adapters = params.trimmomatic.adapters
        ? channel.fromPath(params.trimmomatic.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_adapters = params.fastqc.adapters
        ? channel.fromPath(params.fastqc.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_contaminants = params.fastqc.contaminants
        ? channel.fromPath(params.fastqc.contaminants, checkIfExists: true)
        : channel.value([])

    // -------------------------------------------------------------------------
    // 01 — Raw QC  (isolated: outputs are NOT connected downstream)
    // -------------------------------------------------------------------------
    FASTQC_RAW(ch_reads, ch_fastqc_adapters, ch_fastqc_contaminants)

    // -------------------------------------------------------------------------
    // 02 — Preprocessing
    // -------------------------------------------------------------------------
    TRIMMOMATIC(ch_reads, ch_trimmomatic_adapters)

    // -------------------------------------------------------------------------
    // 03 — Post-trim QC  (isolated: outputs are NOT connected downstream)
    // -------------------------------------------------------------------------
    FASTQC_POST(TRIMMOMATIC.out.trimmed_reads, ch_fastqc_adapters, ch_fastqc_contaminants)

    // -------------------------------------------------------------------------
    // 04 — De-novo transcriptome assembly
    // -------------------------------------------------------------------------
    TRINITY(TRIMMOMATIC.out.trimmed_reads)

    // -------------------------------------------------------------------------
    // 05 — Sequence clustering
    // -------------------------------------------------------------------------
    CDHIT(TRINITY.out.assembly)

    // -------------------------------------------------------------------------
    // 06 — Assembly completeness assessment  
    // -------------------------------------------------------------------------
    BUSCO(CDHIT.out.clustered_fasta)

    // -------------------------------------------------------------------------
    // 07 — Predict protein-coding regions (ORFs) from clustered transcripts
    // CRITICAL: TRANSDECODER requires TWO inputs:
    //   - Input 1: Clustered FASTA from CDHIT
    //   - Input 2: Gene-to-transcript mapping from TRINITY
    // -------------------------------------------------------------------------
    TRANSDECODER(CDHIT.out.clustered_fasta, TRINITY.out.gene_trans_map)

    // -------------------------------------------------------------------------
    // 08 — Load predicted protein sequences into OmicsBox project for annotation
    // -------------------------------------------------------------------------
    LOAD_FASTA(TRANSDECODER.out.predicted_proteins)

    // -------------------------------------------------------------------------
    // 09-11 — Functional annotation 
    // -------------------------------------------------------------------------
    DIAMOND_BLAST(LOAD_FASTA.out.fasta_project)
    BLAST_CHARTS(DIAMOND_BLAST.out.blasted_project)
    INTERPROSCAN(LOAD_FASTA.out.fasta_project)
    IPS_CHARTS(INTERPROSCAN.out.ips_project)
    EGGNOG_MAPPER(TRANSDECODER.out.predicted_proteins)

    // -------------------------------------------------------------------------
    // 12 — Merge Diamond and InterProScan results
    // -------------------------------------------------------------------------
    COMBINE_PROJECTS(DIAMOND_BLAST.out.blasted_project, INTERPROSCAN.out.ips_project)

    // -------------------------------------------------------------------------
    // 13 — Final integrated functional annotation (Diamond + InterPro + EggNOG)
    // -------------------------------------------------------------------------
    MERGE_EGGNOG_5_GOS(COMBINE_PROJECTS.out.combined_project, EGGNOG_MAPPER.out.eggnog_project)
}
