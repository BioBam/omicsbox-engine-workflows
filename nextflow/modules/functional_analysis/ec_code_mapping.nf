// --- FILE: modules/functional_analysis/ec_code_mapping.nf ---
// Wraps: omicsbox enzyme-code-mapping
// Maps Enzyme Commission codes from GO annotations.

process EC_CODE_MAPPING {

    input:
    path project   // OmicsBox project (.box) with GO annotations

    output:
    path "${task.ext.outdir}/project.box", emit: ec_mapped_project   // EC-code-mapped project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox enzyme-code-mapping \\
        --i-project=\$PWD/${project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
