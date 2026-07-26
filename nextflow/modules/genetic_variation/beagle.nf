// --- FILE: modules/genetic_variation/beagle.nf ---
// Wraps: omicsbox beagle
// Genotype Phasing and Imputation with Beagle.

process BEAGLE {

    input:
    path vcf   // VCF to phase and impute

    output:
    path "${task.ext.outdir}/*.vcf{,.gz}", emit: phased_vcf   // Phased/imputed VCF
    path "${task.ext.outdir}/*[Rr]eport*.box", emit: report   // Beagle report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox beagle \\
        --i-gt=\$PWD/${vcf} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
