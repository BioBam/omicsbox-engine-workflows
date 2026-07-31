// --- FILE: modules/functional_analysis/project_charts.nf ---
// Wraps: omicsbox statistics-project
// Generates overall project statistics charts.

process PROJECT_CHARTS {

    input:
    path project   // OmicsBox project (.box)

    output:
    path "${task.ext.outdir}/*.${params.chart_format}", emit: charts, optional: true   // Project statistics charts 

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-project \\
        --i-project=\$PWD/${project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
