// --- FILE: modules/go_annotation_charts.nf ---
// Wraps: omicsbox statistics-annotation  |  backend: LEGACY_SYNC
// Generates GO annotation distribution charts
nextflow.enable.dsl=2

process GO_ANNOTATION_CHARTS {

    input:
    // OmicsBox Annotated Project (.box) emitted by the upstream GO_ANNOTATION step.
    path annotated_project

    output:
    path "${task.ext.outdir}/*", emit: annotation_charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-annotation \\
        --i-project=\$PWD/${annotated_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
