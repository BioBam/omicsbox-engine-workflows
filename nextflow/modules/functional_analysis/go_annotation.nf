// --- FILE: modules/functional_analysis/go_annotation.nf ---
// Wraps: omicsbox annotation
// BLAST2GO functional annotation.

process GO_ANNOTATION {

    input:
    path mapped_project   // GO-mapped OmicsBox project (.box)

    output:
    path "${task.ext.outdir}/project.box", emit: annotated_project   // GO-annotated project

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
