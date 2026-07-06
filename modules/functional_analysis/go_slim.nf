// --- FILE: modules/go_slim.nf ---
// Wraps: omicsbox goslim  |  backend: LEGACY_SYNC
// Generates GO Slim subset annotation
nextflow.enable.dsl=2

process GO_SLIM {

    input:
    // OmicsBox EC-mapped project (.box) emitted by the upstream EC_CODE_MAPPING step.
    path project_file

    output:
    path "${task.ext.outdir}/*", emit: goslim_project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox goslim \\
        --i-project=\$PWD/${project_file} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
