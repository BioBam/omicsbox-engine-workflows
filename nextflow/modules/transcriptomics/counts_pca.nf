// --- FILE: modules/transcriptomics/counts_pca.nf ---
// Wraps: omicsbox counts-pca
// PCA/PCoA visualization of sample distances.

process COUNTS_PCA {

    input:
    path count_table_project   // AbstractCountTable .box
    path design_file           // Optional: experimental design TSV

    output:
    path "${task.ext.outdir}/*.${params.chart_format}", emit: pca_chart   // PCA/PCoA chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // Optional-input convention: an unwired design file arrives as channel.value([]), which
    // Nextflow stages as a file literally named '[]' - that's the "not provided" case to skip.
    def design_flag = (design_file.name != '[]')
        ? "--i-experimental-design=\$PWD/${design_file}"
        : ""

    """
    mkdir -p ${outdir}
    omicsbox counts-pca \\
        --i-count-table=\$PWD/${count_table_project} \\
        ${design_flag} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
