// --- FILE: modules/genetic_variation/gwas.nf ---
// Wraps: omicsbox gwas
// Genome-Wide Association Study (GWAS): tests association between genotypes (VCF) and phenotypic traits.

process GWAS {

    input:
    path vcf                // Input VCF with SNPs to test for association
    path pheno              // Phenotype/traits table (sample names in first column, header required)
    path kinship            // Optional: precomputed kinship matrix (requires --use-kinship=true)
    path covariate_matrix   // Optional: covariate matrix metadata (requires --use-covariate-matrix=true)

    output:
    path "${task.ext.outdir}/*results*.box", emit: gwas_results   // GWAS association results
    path "${task.ext.outdir}/*report*.box", emit: gwas_report     // GWAS summary report
    path "${task.ext.outdir}/output/*corrected_phenotype*", emit: corrected_phenotype, optional: true   // Normalized phenotype table (when --normalize=true)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // Optional-input convention: when kinship/covariate files aren't wired in, the workflow passes
    // an empty List (channel.value([])) instead of a real path - that's the "not provided" case to skip.
    def kinship_flag = (!(kinship instanceof List) || !kinship.isEmpty())
        ? "--i-kinship=\$PWD/${kinship}"
        : ""
    def covariate_flag = (!(covariate_matrix instanceof List) || !covariate_matrix.isEmpty())
        ? "--i-covariate-matrix=\$PWD/${covariate_matrix}"
        : ""

    """
    mkdir -p ${outdir}
    omicsbox gwas \\
        --i-input-vcf=\$PWD/${vcf} \\
        --i-input-pheno=\$PWD/${pheno} \\
        ${kinship_flag} \\
        ${covariate_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
