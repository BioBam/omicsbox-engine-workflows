// --- FILE: modules/blast_charts.nf ---
// Wraps: omicsbox statistics-blast  |  backend: WJOB_ASYNC
// Generates visualization charts for DIAMOND BLAST results
nextflow.enable.dsl=2

process BLAST_CHARTS {

    input:
    // OmicsBox project (.box) with BLAST hits emitted by the upstream DIAMOND_BLAST step.
    path blasted_project

    output:
    path "${task.ext.outdir}/*", emit: blast_charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-blast \\
        --i-project=\$PWD/${blasted_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
