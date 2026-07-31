// --- FILE: modules/functional_analysis/go_mapping_charts.nf ---
// Wraps: omicsbox statistics-mapping
// Generates GO mapping distribution charts.

process GO_MAPPING_CHARTS {

    input:
    path project   // OmicsBox project (.box) with GO mappings

    output:
    path "${task.ext.outdir}/*.${params.chart_format}", emit: charts, optional: true   // GO mapping distribution charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-mapping \\
        --i-project=\$PWD/${project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
