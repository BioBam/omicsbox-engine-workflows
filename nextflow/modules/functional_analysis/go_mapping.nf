// --- FILE: modules/functional_analysis/go_mapping.nf ---
// Wraps: omicsbox mapping-cloud
// Maps sequences to Gene Ontology terms.

process GO_MAPPING {

    input:
    path project   // OmicsBox project (.box) with BLAST hits

    output:
    path "${task.ext.outdir}/project.box", emit: mapped_project   // GO-mapped project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox mapping-cloud \\
        --i-project=\$PWD/${project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
