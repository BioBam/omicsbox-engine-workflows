// --- FILE: modules/export_annotations/export_genesets.nf ---
// Wraps: omicsbox export-genesets
// Exports annotated gene sets to standard formats.

process EXPORT_GENE_SETS {

    input:
    path project_file   // OmicsBox project (.box) with EC-mapped annotations

    output:
    path "${task.ext.outdir}/*", emit: genesets_file   // Exported gene sets in the selected output format

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox export-genesets \\
        --i-project=\$PWD/${project_file} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
