// --- FILE: modules/diamond_blast.nf ---
// Wraps: omicsbox diamond  |  backend: WJOB_ASYNC
// Sequence similarity search via DIAMOND BLAST.
nextflow.enable.dsl=2

process DIAMOND_BLAST {

    input:
    path omicsbox_project   // OmicsBox Sequence Project (.box) 

    output:
    path "${task.ext.outdir}/*", emit: blasted_project  // BLAST-annotated OmicsBox project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox diamond \\
        --i-local-project=\$PWD/${omicsbox_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
