// --- FILE: modules/genetic_variation/variant_filtering.nf ---
// Wraps: omicsbox variant-filtering-freebayes
// Variant Filtering: filters a VCF by quality/depth/MAF/missingness criteria.

process VARIANT_FILTERING {

    input:
    path vcf   // Variant file (VCF or VCF.gz) to filter

    output:
    path "${task.ext.outdir}/*.vcf{,.gz}", emit: filtered_vcf               // Filtered variants VCF
    path "${task.ext.outdir}/*[Rr]eport*.box", emit: report                // Variant filtering report
    path "${task.ext.outdir}/*{depth,quality,maf}*.${params.chart_format}", emit: charts   // Depth, quality, and MAF charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox variant-filtering-freebayes \\
        --i-input-file=\$PWD/${vcf} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
