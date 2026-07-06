// --- FILE: modules/busco.nf ---
// Wraps: omicsbox busco  |  backend: WJOB_ASYNC
// Assesses assembly completeness against a BUSCO lineage database.
nextflow.enable.dsl=2

process BUSCO {

    input:
    path sequences   

    output:
    path "${task.ext.outdir}/*.box", emit: busco_results
    path "${task.ext.outdir}/*report*.box", emit: report        // OmicsBox report
    path "${task.ext.outdir}/*chart*", emit: busco_chart        // BUSCO chart visualization    

    script:
    def outdir     = task.ext.outdir ?: task.process.toLowerCase()
    def args       = task.ext.args   ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox busco \\
        --i-sequences=\$PWD/${sequences} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
