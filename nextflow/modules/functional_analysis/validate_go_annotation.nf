// --- FILE: modules/validate_go_annotation.nf ---
// Wraps: omicsbox annotation-validate  |  backend: LEGACY_SYNC
// Validates GO annotations using True-Path-Rule
nextflow.enable.dsl=2

process VALIDATE_GO_ANNOTATION {

    input:
    // Integrated OmicsBox project (.box) emitted by the upstream MERGE_IPS_GOS_TO_ANNOTATION step.
    path final_project

    output:
    path "${task.ext.outdir}/*", emit: validated_project

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
