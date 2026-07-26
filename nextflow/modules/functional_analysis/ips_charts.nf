// --- FILE: modules/functional_analysis/ips_charts.nf ---
// Wraps: omicsbox statistics-interpro
// Generates InterProScan domain distribution charts.

process IPS_CHARTS {

    input:
    path ips_project   // OmicsBox IPS Project (.box)

    output:
    path "${task.ext.outdir}/interproscan-families-distribution.${params.chart_format}", emit: families_chart  // InterPro families distribution chart
    path "${task.ext.outdir}/interproscan-results.${params.chart_format}", emit: results_chart                 // InterProScan results chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox statistics-interpro \\
        --i-project=\$PWD/${ips_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
