// --- FILE: modules/merge_eggnog_5_gos.nf ---
// Wraps: omicsbox merge-emapper5-annotations  |  backend: LEGACY_SYNC
// Integrates EggNOG annotations with GO terms
nextflow.enable.dsl=2

process MERGE_EGGNOG_5_GOS {

    input:
    // Integrated project (.box) from MERGE_IPS_GOS_TO_ANNOTATION and EggNOG annotations (.box) from EGGNOG_MAPPER.
    path integrated_project
    path eggnog_project

    output:
    path "${task.ext.outdir}/project.box",             emit: final_project
    path "${task.ext.outdir}/merge-orthology-groups-go-annotation.${params.chart_format}", emit: merge_eggnog_chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox merge-emapper5-annotations  \\
        --i-project=\$PWD/${integrated_project} \\
        --i-egg-nog-annotations=\$PWD/${eggnog_project} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
