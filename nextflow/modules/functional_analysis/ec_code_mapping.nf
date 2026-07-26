// --- FILE: modules/functional_analysis/ec_code_mapping.nf ---
// Wraps: omicsbox enzymecode
// Maps Enzyme Commission codes from GO annotations.

process EC_CODE_MAPPING {

    input:
    path validated_project   // GO-annotated OmicsBox project (.box)

    output:
    path "${task.ext.outdir}/project.box", emit: ec_mapped_project   // EC-code-mapped project

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
