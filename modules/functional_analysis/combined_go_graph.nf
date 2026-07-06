// --- FILE: modules/combined_go_graph.nf ---
// Wraps: omicsbox graph-combined-make  |  backend: LEGACY_SYNC
// Generates combined GO graph visualization
nextflow.enable.dsl=2

process COMBINED_GO_GRAPH {

    input:
    // OmicsBox EC-mapped project (.box) emitted by the upstream EC_CODE_MAPPING step.
    path validated_project

    output:
    path "${task.ext.outdir}/*", emit: combined_graph

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
