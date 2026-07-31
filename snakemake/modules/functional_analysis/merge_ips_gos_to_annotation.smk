# --- FILE: modules/functional_analysis/merge_ips_gos_to_annotation.smk ---
# Wraps: omicsbox interproscan-join - merges InterPro domains into GO annotations.
#
# Generic, reusable rule (operation = `interproscan_join`). Writes a project box
# plus a named chart (both declared exactly in the workflow). Instantiate:
#   use rule interproscan_join as <step> with:
#       input:  project=<upstream project box>
#       output: project=<step>/project.box, chart=<step>/merge-...-results.<fmt>
#       params: outdir=stage("<step>"), chart_format=CHART_FORMAT, args=join_args("<step>")
#       log:    logfile("<step>")


rule interproscan_join:
    shell:
        r"""
        (
            omicsbox interproscan-join \
                --i-project="{input.project}" \
                --chart-format={params.chart_format} \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
