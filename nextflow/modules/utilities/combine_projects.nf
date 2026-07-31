// --- FILE: modules/utilities/combine_projects.nf ---
// Wraps: omicsbox combine-projects
// Merges multiple OmicsBox projects into one.

process COMBINE_PROJECTS {

    input:
    path project1         // First OmicsBox project (.box) to merge (--i-project1)
    path project2   // Second OmicsBox project (.box) to merge (--i-project2)

    output:
    path "${task.ext.outdir}/combined_project.box", emit: combined_project   // Merged OmicsBox project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox combine-projects \\
        --i-project1=\$PWD/${project1} \\
        --i-project2=\$PWD/${project2} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
