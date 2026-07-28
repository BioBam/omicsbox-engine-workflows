// --- FILE: modules/functional_analysis/combined_go_graph.nf ---
// Wraps: omicsbox graph-combined-make
// Generates combined GO graph visualization.

process COMBINED_GO_GRAPH {

    input:
    path project   // OmicsBox project (.box) with GO annotations

    output:
    path "${task.ext.outdir}/graph*.box", emit: go_graphs   // Combined GO graph(s)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox graph-combined-make \\
        --i-project=\$PWD/${project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
