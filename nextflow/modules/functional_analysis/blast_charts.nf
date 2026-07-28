// --- FILE: modules/functional_analysis/blast_charts.nf ---
// Wraps: omicsbox statistics-blast
// Generates visualization charts for BLAST hit statistics.

process BLAST_CHARTS {

    input:
    path project   // OmicsBox project (.box) with BLAST hits

    output:
    path "${task.ext.outdir}/*.${params.chart_format}", emit: charts, optional: true   // BLAST statistics charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-blast \\
        --i-project=\$PWD/${project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
