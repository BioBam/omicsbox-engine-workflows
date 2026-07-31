// --- FILE: modules/genome_analysis/busco.nf ---
// Wraps: omicsbox busco
// Assesses assembly completeness against a BUSCO lineage database.

process BUSCO {

    input:
    path sequences   // Assembly sequences to evaluate (FASTA)

    output:
    path "${task.ext.outdir}/*project*.box", emit: busco_project           // BUSCO OmicsBox project
    path "${task.ext.outdir}/*report*.box", emit: report                   // BUSCO completeness report
    path "${task.ext.outdir}/*chart*.box", emit: chart  // BUSCO chart (extension follows chart_format)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''


    """
    mkdir -p ${outdir}
    omicsbox busco \\
        --i-sequences=\$PWD/${sequences} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
