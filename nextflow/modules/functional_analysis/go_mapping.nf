// --- FILE: modules/functional_analysis/go_mapping.nf ---
// Wraps: omicsbox mapping-cloud
// Maps sequences to Gene Ontology terms.

process GO_MAPPING {

    input:
    path blasted_project   // BLAST-annotated OmicsBox project (.box)

    output:
    path "${task.ext.outdir}/project.box", emit: mapped_project   // GO-mapped project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox mapping-cloud \\
        --i-project=\$PWD/${blasted_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
