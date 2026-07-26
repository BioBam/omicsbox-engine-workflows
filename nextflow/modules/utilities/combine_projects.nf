// --- FILE: modules/utilities/combine_projects.nf ---
// Wraps: omicsbox combine-projects
// Merges multiple OmicsBox projects into one.

process COMBINE_PROJECTS {

    input:
    path ips_project         // OmicsBox project (.box) containing InterProScan domain annotations
    path annotated_project   // OmicsBox project (.box) containing GO functional annotations

    output:
    path "${task.ext.outdir}/combined_project.box", emit: combined_project   // Merged OmicsBox project

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
