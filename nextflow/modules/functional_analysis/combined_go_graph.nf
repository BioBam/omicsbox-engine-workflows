// --- FILE: modules/functional_analysis/combined_go_graph.nf ---
// Wraps: omicsbox graph-combined-make
// Generates combined GO graph visualization.

process COMBINED_GO_GRAPH {

    input:
    path validated_project   // EC-mapped OmicsBox project (.box)

    output:
    path "${task.ext.outdir}/graph*.${params.chart_format}", emit: go_graphs   // Combined GO graph chart(s)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox graph-combined-make \\
        --i-project=\$PWD/${validated_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
