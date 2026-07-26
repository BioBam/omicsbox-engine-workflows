// --- FILE: modules/functional_analysis/project_charts.nf ---
// Wraps: omicsbox statistics-project
// Generates overall project statistics charts.

process PROJECT_CHARTS {

    input:
    path validated_project   // Validated OmicsBox project (.box)

    output:
    path "${task.ext.outdir}/*.${params.chart_format}", emit: project_charts   // Final annotation charts (extension follows chart_format)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-project \\
        --i-project=\$PWD/${validated_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
