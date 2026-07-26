// --- FILE: modules/functional_analysis/validate_go_annotation.nf ---
// Wraps: omicsbox annotation-validate
// Validates GO annotations using True-Path-Rule.

process VALIDATE_GO_ANNOTATION {

    input:
    path final_project   // Merged OmicsBox project (.box) with combined GO annotations

    output:
    path "${task.ext.outdir}/project.box", emit: validated_project   // Validated GO-annotation project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox annotation-validate \\
        --i-project=\$PWD/${final_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
