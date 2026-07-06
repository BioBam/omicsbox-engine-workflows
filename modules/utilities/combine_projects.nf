// --- FILE: modules/combine_projects.nf ---
// Wraps: omicsbox combine-projects  |  backend: LEGACY_SYNC
// Merges multiple OmicsBox projects into one
nextflow.enable.dsl=2

process COMBINE_PROJECTS {

    input:
    // IPS project (.box) from INTERPROSCAN and annotated project (.box) from GO_ANNOTATION.
    path ips_project
    path annotated_project

    output:
    path "${task.ext.outdir}/*", emit: combined_project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox combine-projects \\
        --i-project1=\$PWD/${ips_project} \\
        --i-project2=\$PWD/${annotated_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
