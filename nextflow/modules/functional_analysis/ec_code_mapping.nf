// --- FILE: modules/ec_code_mapping.nf ---
// Wraps: omicsbox enzymecode  |  backend: LEGACY_SYNC
// Maps Enzyme Commission codes from GO annotations
nextflow.enable.dsl=2

process EC_CODE_MAPPING {

    input:
    // Validated OmicsBox project (.box) emitted by the upstream VALIDATE_GO_ANNOTATION step.
    path validated_project

    output:
    path "${task.ext.outdir}/*", emit: ec_mapped_project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox enzymecode \\
        --i-project=\$PWD/${validated_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
