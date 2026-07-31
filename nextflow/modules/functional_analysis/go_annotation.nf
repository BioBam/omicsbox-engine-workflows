// --- FILE: modules/functional_analysis/go_annotation.nf ---
// Wraps: omicsbox annotation
// BLAST2GO functional annotation.

process GO_ANNOTATION {

    input:
    path project   // OmicsBox project (.box) with GO mappings

    output:
    path "${task.ext.outdir}/project.box", emit: annotated_project   // GO-annotated project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox annotation \\
        --i-project=\$PWD/${project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
