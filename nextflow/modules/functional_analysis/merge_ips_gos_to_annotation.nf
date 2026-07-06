// --- FILE: modules/merge_ips_gos_to_annotation.nf ---
// Wraps: omicsbox interproscan-join  |  backend: LEGACY_SYNC
// Merges InterPro domains into GO annotations
nextflow.enable.dsl=2

process MERGE_IPS_GOS_TO_ANNOTATION {

    input:
    // Combined OmicsBox project (.box) emitted by the upstream COMBINE_PROJECTS step.
    path combined_project

    output:
    path "${task.ext.outdir}/project.box",               emit: integrated_project
    path "${task.ext.outdir}/merge-interpro-annotation-results.${params.chart_format}",   emit: merge_chart

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
