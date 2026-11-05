# --- FILE: modules/functional_analysis/go_mapping_charts.smk ---
# Wraps: omicsbox go-mapping-charts - GO mapping charts (terminal step).
#
# Generic, reusable rule (operation = `statistics_mapping`). Instantiate with:
#   use rule statistics_mapping as <step> with:
#       input:  project=<upstream project box>
#       output: directory(<step folder>)
#       params: chart_format=CHART_FORMAT, args=join_args("<step>")
#       log:    logfile("<step>")


rule statistics_mapping:
    shell:
        r"""
        (
            mkdir -p {output}
            omicsbox go-mapping-charts \
                --i-project="{input.project}" \
                --chart-format={params.chart_format} \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
