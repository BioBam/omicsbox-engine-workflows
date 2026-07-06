// --- FILE: modules/go_mapping_charts.nf ---
// Wraps: omicsbox statistics-mapping  |  backend: LEGACY_SYNC
// Generates GO mapping distribution charts
nextflow.enable.dsl=2

process GO_MAPPING_CHARTS {

    input:
    // OmicsBox GO Mapped Project (.box) emitted by the upstream GO_MAPPING step.
    path mapped_project

    output:
    path "${task.ext.outdir}/*", emit: mapping_charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-mapping \\
        --i-project=\$PWD/${mapped_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
