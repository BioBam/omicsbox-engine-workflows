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

    // --design is injected HERE, paired with the file, rather than left in ext.args: the CLI
    // rejects --i-experimental-design outright when --design=false, so the two must always agree. 
    def use_design = (params.counts_pca?.use_design != false)

    def has_design = !(design_file instanceof List) || !design_file.isEmpty()

    def design_flag = (use_design && has_design)
        ? "--design=true --i-experimental-design=\$PWD/${design_file}"
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
