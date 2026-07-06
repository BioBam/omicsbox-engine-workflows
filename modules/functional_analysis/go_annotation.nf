// --- FILE: modules/go_annotation.nf ---
// Wraps: omicsbox annotation  |  backend: WJOB_ASYNC
// BLAST2GO functional annotation
nextflow.enable.dsl=2

process GO_ANNOTATION {

    input:
    // OmicsBox GO Mapped Project (.box) emitted by the upstream GO_MAPPING step.
    path mapped_project

    output:
    path "${task.ext.outdir}/*", emit: annotated_project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox annotation \\
        --i-project=\$PWD/${mapped_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
