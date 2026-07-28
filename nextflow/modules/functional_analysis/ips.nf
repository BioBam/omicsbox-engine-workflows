// --- FILE: modules/functional_analysis/ips.nf ---
// Wraps: omicsbox ips
// Protein domain and functional annotation via InterProScan.

process INTERPROSCAN {

    input:
    path omicsbox_project   // OmicsBox Sequence Project (.box)

    output:
    path "${task.ext.outdir}/*output_project*.box", emit: ips_project    // InterProScan-annotated project
    path "${task.ext.outdir}/*.gff3", emit: gff3, optional: true         // InterProScan GFF3 result(s)
    path "${task.ext.outdir}/*.xml", emit: xml, optional: true           // InterProScan XML result(s)
    path "${task.ext.outdir}/*.tsv", emit: tsv, optional: true           // InterProScan TSV result(s)
    path "${task.ext.outdir}/*.json", emit: json, optional: true         // InterProScan JSON result(s)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox ips \\
        --i-local-project=\$PWD/${omicsbox_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}