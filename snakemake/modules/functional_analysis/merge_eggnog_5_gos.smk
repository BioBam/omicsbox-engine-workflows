# --- FILE: modules/functional_analysis/merge_eggnog_5_gos.smk ---
# Wraps: omicsbox merge-emapper5-annotations - integrates EggNOG annotations
# with GO terms. Two inputs (the upstream project + the EggNOG annotations).
#
# Generic, reusable rule (operation = `merge_emapper5_annotations`). Writes a
# project box plus a named chart (both declared exactly in the workflow):
#   use rule merge_emapper5_annotations as <step> with:
#       input:  project=<upstream project box>, eggnog=<eggnog annotations box>
#       output: project=<step>/project.box, chart=<step>/merge-...-annotation.<fmt>
#       params: outdir=stage("<step>"), chart_format=CHART_FORMAT, args=join_args("<step>")
#       log:    logfile("<step>")


rule merge_emapper5_annotations:
    shell:
        r"""
        (
            omicsbox merge-emapper5-annotations \
                --i-project="{input.project}" \
                --i-egg-nog-annotations="{input.eggnog}" \
                --chart-format={params.chart_format} \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
