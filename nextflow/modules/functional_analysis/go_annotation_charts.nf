// --- FILE: modules/functional_analysis/go_annotation_charts.nf ---
// Wraps: omicsbox statistics-annotation
// Generates GO annotation distribution charts.

process GO_ANNOTATION_CHARTS {

    input:
    path project   // OmicsBox project (.box) with GO annotations

    output:
    path "${task.ext.outdir}/annotation-distribution.${params.chart_format}", emit: annotation_chart   // Annotation distribution chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-annotation \\
        --i-project=\$PWD/${project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
