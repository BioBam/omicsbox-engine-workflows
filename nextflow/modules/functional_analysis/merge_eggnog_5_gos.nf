// --- FILE: modules/functional_analysis/merge_eggnog_5_gos.nf ---
// Wraps: omicsbox merge-emapper5-annotations
// Integrates EggNOG annotations with GO terms.

process MERGE_EGGNOG_5_GOS {

    input:
    path project   // OmicsBox project (.box) with GO annotations
    path eggnog_project       // EggNOG-Mapper annotation project (.box)

    output:
    path "${task.ext.outdir}/project.box",             emit: merged_project                    // Merged OmicsBox project with EggNOG-integrated GO annotations
    path "${task.ext.outdir}/merge-orthology-groups-go-annotation.${params.chart_format}", emit: merge_eggnog_chart   // EggNOG/GO merge results chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox merge-emapper5-annotations  \\
        --i-project=\$PWD/${project} \\
        --i-egg-nog-annotations=\$PWD/${eggnog_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
