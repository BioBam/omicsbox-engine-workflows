// --- FILE: modules/functional_analysis/ips_charts.nf ---
// Wraps: omicsbox interproscan-charts
// Generates InterProScan domain distribution charts.

process IPS_CHARTS {

    input:
    path project   // OmicsBox project (.box) with InterProScan results

    output:
    path "${task.ext.outdir}/*.${params.chart_format}", emit: charts, optional: true   // InterProScan distribution charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox interproscan-charts \\
        --i-project=\$PWD/${project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
