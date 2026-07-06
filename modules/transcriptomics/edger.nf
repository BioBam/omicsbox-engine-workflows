// --- FILE: modules/edger.nf ---
// Wraps: omicsbox edger  |  backend: WJOB_ASYNC
// Pairwise differential expression analysis with edgeR.
nextflow.enable.dsl=2

process EDGER {

    input:
    path count_table_project  
    path design_file           // Tab-delimited experimental design file 

    output:
    path "${task.ext.outdir}/*output*.box",  emit: results  // EdgeRObject project containing pairwise analysis results
    path "${task.ext.outdir}/*report*.box", emit: report   //  Report

    script:
    def outdir     = task.ext.outdir ?: task.process.toLowerCase()
    def args       = task.ext.args   ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox edger \\
        --i-count-table=\$PWD/${count_table_project} \\
        --i-file-design-table=\$PWD/${design_file} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
