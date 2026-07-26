// =============================================================================
// FILE: genetic_variation_analysis.nf
// Genetic Variation Analysis Pipeline:
//   QC -> Trimming -> Alignment (BWA) -> Variant Calling (BCFtools) ->
//   Variant Filtering -> Phasing/Imputation (Beagle) -> GWAS,
//   with a parallel Variant Annotation branch off the filtered variants.
// =============================================================================

include { FASTQC as FASTQC_RAW   } from '../../modules/general_tools/fastqc.nf'
include { TRIMMOMATIC            } from '../../modules/general_tools/trimmomatic.nf'
include { FASTQC as FASTQC_POST  } from '../../modules/general_tools/fastqc.nf'
include { BWA                    } from '../../modules/genome_analysis/bwa.nf'
include { BCFTOOLS               } from '../../modules/genetic_variation/bcftools.nf'
include { VARIANT_FILTERING      } from '../../modules/genetic_variation/variant_filtering.nf'
include { BEAGLE                 } from '../../modules/genetic_variation/beagle.nf'
include { GWAS                   } from '../../modules/genetic_variation/gwas.nf'
include { VARIANT_ANNOTATION     } from '../../modules/genetic_variation/variant_annotation.nf'

// =============================================================================
workflow {

    main:

    // -------------------------------------------------------------------------
    // Config template export: --dump_config copies this workflow's .config to
    // the launch directory and exits, so the user can edit it and pass it via -c.
    // -------------------------------------------------------------------------
    if (params.dump_config) {
        // 1. Source: this workflow's config template (sibling of the .nf; projectDir = workflow dir under -main-script)
        def sourceConfig = file("${moduleDir}/genetic_variation_analysis.config")

        // 2. Target: the current launch directory
        def targetConfig = file("./genetic_variation_analysis.config")

        if (sourceConfig.exists()) {
            // 3. Physically copy the file to the user's environment
            sourceConfig.copyTo(targetConfig)

            log.info "========================================================================="
            log.info "  [OK] Configuration template successfully exported!"
            log.info "========================================================================="
            log.info "  File generated at: ./genetic_variation_analysis.config"
            log.info ""
            log.info "  Instructions:"
            log.info "  1. Open and modify the parameters in the generated file as needed."
            log.info "  2. Run the actual pipeline pointing to your local configuration using:"
            log.info "     -c genetic_variation_analysis.config"
            log.info "========================================================================="
        } else {
            log.error "  [ERROR] Could not find the internal template at: ${sourceConfig}"
        }

        // 4. Stop Nextflow safely with exit code 0 (success)
        exit 0
    }


    // -------------------------------------------------------------------------
    // Safety checks - critical inputs
    // -------------------------------------------------------------------------
    if (!params.input_paired_end && !params.input_single_end) {
        exit 1, "ERROR: You must provide reads via --input_paired_end or --input_single_end."
    }
    if (params.input_paired_end && params.input_single_end) {
        exit 1, "ERROR: Provide either --input_paired_end or --input_single_end, not both."
    }
    if (!params.input_fasta) {
        exit 1, "ERROR: You must provide a reference genome FASTA via --input_fasta (used by BWA, BCFtools and Variant Annotation)."
    }
    if (!params.variant_annotation.annotation) {
        exit 1, "ERROR: You must provide an annotation GTF via --variant_annotation.annotation (used by Variant Annotation)."
    }
    if (!params.gwas.input_pheno) {
        exit 1, "ERROR: You must provide a phenotype/traits file via --gwas.input_pheno (used by GWAS)."
    }

    // -------------------------------------------------------------------------
    // Channel creation
    // ARCHITECTURAL NOTE: .collect() gathers all reads into ONE list so a single
    // OmicsBox task is spawned. Single-file inputs use .first() (value channel);
    // the reference genome is one value channel reused by BWA, BCFtools and annotation.
    // -------------------------------------------------------------------------
    def ch_reads = params.input_single_end
        ? channel.fromPath(params.input_single_end, checkIfExists: true).collect()
        : channel.fromPath(params.input_paired_end, checkIfExists: true).collect()

    def ch_reference = channel.fromPath(params.input_fasta, checkIfExists: true).first()
    def ch_gff = channel.fromPath(params.variant_annotation.annotation, checkIfExists: true).first()
    def ch_pheno = channel.fromPath(params.gwas.input_pheno, checkIfExists: true).first()

    // Optional file inputs - channel.value([]) acts as a safe "not provided" placeholder
    def ch_trimmomatic_adapters = params.trimmomatic.adapters
        ? channel.fromPath(params.trimmomatic.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_adapters = params.fastqc.adapters
        ? channel.fromPath(params.fastqc.adapters, checkIfExists: true)
        : channel.value([])

    def ch_fastqc_contaminants = params.fastqc.contaminants
        ? channel.fromPath(params.fastqc.contaminants, checkIfExists: true)
        : channel.value([])

    // Optional: BCFtools sample->group file (only used when --use-groups=true)
    def ch_group = params.bcftools.group_experiment
        ? channel.fromPath(params.bcftools.group_experiment, checkIfExists: true).first()
        : channel.value([])

    // Optional: GWAS kinship / covariate matrices (see config coupling notes)
    def ch_kinship = params.gwas.kinship
        ? channel.fromPath(params.gwas.kinship, checkIfExists: true).first()
        : channel.value([])

    def ch_covariate = params.gwas.covariate_matrix
        ? channel.fromPath(params.gwas.covariate_matrix, checkIfExists: true).first()
        : channel.value([])

    // -------------------------------------------------------------------------
    // 01 - Raw quality assessment (isolated: outputs are NOT connected downstream)
    // -------------------------------------------------------------------------
    FASTQC_RAW(ch_reads, ch_fastqc_adapters, ch_fastqc_contaminants)

    // -------------------------------------------------------------------------
    // 02 - Preprocessing & adapter/quality trimming
    // -------------------------------------------------------------------------
    TRIMMOMATIC(ch_reads, ch_trimmomatic_adapters)

    // -------------------------------------------------------------------------
    // 03 - Quality assessment (post-trimming, isolated)
    // -------------------------------------------------------------------------
    FASTQC_POST(TRIMMOMATIC.out.trimmed_reads, ch_fastqc_adapters, ch_fastqc_contaminants)

    // -------------------------------------------------------------------------
    // 04 - Read alignment to the reference genome (BWA takes: reference, reads)
    // -------------------------------------------------------------------------
    BWA(ch_reference, TRIMMOMATIC.out.trimmed_reads)

    // -------------------------------------------------------------------------
    // 05 - Variant calling (BCFtools) from the BAM(s) + reference genome
    // -------------------------------------------------------------------------
    BCFTOOLS(BWA.out.sorted_bam, ch_reference, ch_group)

    // -------------------------------------------------------------------------
    // 06 - Variant filtering (quality/depth/MAF/missingness)
    // -------------------------------------------------------------------------
    VARIANT_FILTERING(BCFTOOLS.out.vcf)

    // -------------------------------------------------------------------------
    // 07 - Genotype phasing & imputation (Beagle). Produces the VCF for GWAS.
    // -------------------------------------------------------------------------
    BEAGLE(VARIANT_FILTERING.out.filtered_vcf)

    // -------------------------------------------------------------------------
    // 08 - GWAS: association test using the phased/imputed VCF from Beagle.
    // -------------------------------------------------------------------------
    GWAS(BEAGLE.out.phased_vcf, ch_pheno, ch_kinship, ch_covariate)

    // -------------------------------------------------------------------------
    // 09 - Variant annotation: parallel branch off the FILTERED variants, not the phased VCF.
    // CRITICAL: Beagle strips the VCF ##contig headers (and drops unplaced scaffolds), so its
    // phased VCF no longer matches the genome and OmicsBox rejects it. The filtered VCF keeps
    // bcftools' ##contig headers, so annotation reads from it instead.
    // -------------------------------------------------------------------------
    VARIANT_ANNOTATION(VARIANT_FILTERING.out.filtered_vcf, ch_gff, ch_reference)

}
