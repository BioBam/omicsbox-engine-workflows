// --- FILE: modules/project_charts.nf ---
// Wraps: omicsbox statistics-project  |  backend: LEGACY_SYNC
// Generates overall project statistics charts
nextflow.enable.dsl=2

process PROJECT_CHARTS {

    input:
    // OmicsBox EC-mapped project (.box) emitted by the upstream EC_CODE_MAPPING step.
    path validated_project

    output:
    path "${task.ext.outdir}/*", emit: project_charts

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
