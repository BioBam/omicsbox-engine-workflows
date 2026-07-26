// --- FILE: modules/functional_analysis/merge_ips_gos_to_annotation.nf ---
// Wraps: omicsbox interproscan-join
// Merges InterPro domains into GO annotations.

process MERGE_IPS_GOS_TO_ANNOTATION {

    input:
    path combined_project   // Combined OmicsBox project (.box)

    output:
    path "${task.ext.outdir}/project.box",               emit: integrated_project           // Integrated OmicsBox project (.box)
    path "${task.ext.outdir}/merge-interpro-annotation-results.${params.chart_format}",   emit: merge_chart   // InterPro/GO merge results chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox interproscan-join \\
        --i-project=\$PWD/${combined_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
