// --- FILE: modules/functional_analysis/go_slim.nf ---
// Wraps: omicsbox goslim
// Generates GO Slim subset annotation.

process GO_SLIM {

    input:
    path project_file   // EC-mapped OmicsBox project (.box)
    path obo_file       // Optional: custom GO-Slim OBO file

    output:
    path "${task.ext.outdir}/*", emit: goslim_project   // GO-Slim annotated project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // Optional-input convention: when no OBO file is wired in, the workflow passes an empty
    // List (channel.value([])) instead of a real path - that's the "not provided" case to skip.
    // Only takes effect when args also sets --option=custom (which disables --go-slim-web-file).
    def obo_flag = (!(obo_file instanceof List) || !obo_file.isEmpty())
        ? "--i-go-slim-obo-file=\$PWD/${obo_file}"
        : ""

    """
    mkdir -p ${outdir}
    omicsbox goslim \\
        --i-project=\$PWD/${project_file} \\
        ${obo_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
