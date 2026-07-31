# --- FILE: modules/functional_analysis/ips_charts.smk ---
# Wraps: omicsbox statistics-interpro - InterProScan charts (terminal step).
#
# Generic, reusable rule (operation = `statistics_interpro`). Instantiate with:
#   use rule statistics_interpro as <step> with:
#       input:  project=<upstream project box>
#       output: directory(<step folder>)
#       params: chart_format=CHART_FORMAT, args=join_args("<step>")
#       log:    logfile("<step>")


rule statistics_interpro:
    shell:
        r"""
        (
            mkdir -p {output}
            omicsbox statistics-interpro \
                --i-project="{input.project}" \
                --chart-format={params.chart_format} \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
