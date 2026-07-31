# --- FILE: modules/functional_analysis/project_charts.smk ---
# Wraps: omicsbox statistics-project - overall project statistics charts.
#
# Generic, reusable rule (operation = `statistics_project`). Instantiate with:
#   use rule statistics_project as <step> with:
#       input:  project=<upstream project box>
#       output: directory(<step folder>)
#       params: chart_format=CHART_FORMAT, args=join_args("<step>")
#       log:    logfile("<step>")


rule statistics_project:
    shell:
        r"""
        (
            mkdir -p {output}
            omicsbox statistics-project \
                --i-project="{input.project}" \
                --chart-format={params.chart_format} \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
