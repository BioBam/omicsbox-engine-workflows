// --- FILE: modules/transcriptomics/edger.nf ---
// Wraps: omicsbox edger
// Pairwise differential expression analysis with edgeR.

process EDGER {

    input:
    path count_table_project   // AbstractCountTable project (.box)
    path design_file           // Tab-delimited experimental design file

    output:
    path "${task.ext.outdir}/*output*.box",  emit: results  // EdgeRObject project (pairwise DE results)
    path "${task.ext.outdir}/*report*.box", emit: report   // EdgeR report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''


    """
    mkdir -p ${outdir}
    omicsbox edger \\
        --i-count-table=\$PWD/${count_table_project} \\
        --i-file-design-table=\$PWD/${design_file} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
