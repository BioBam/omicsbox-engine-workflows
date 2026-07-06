// --- FILE: modules/export_genesets.nf ---
// Wraps: omicsbox export-genesets  |  backend: LEGACY_SYNC
// Exports annotated gene sets to standard formats
nextflow.enable.dsl=2

process EXPORT_GENE_SETS {

    input:
    // OmicsBox EC-mapped project (.box) emitted by the upstream EC_CODE_MAPPING step.
    path project_file

    output:
    path "${task.ext.outdir}/*", emit: genesets_file

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
