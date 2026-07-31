# --- FILE: modules/functional_analysis/go_annotation_charts.smk ---
# Wraps: omicsbox statistics-annotation - GO annotation distribution charts.
#
# ONE generic, reusable rule (operation = `statistics_annotation`). Several steps
# chart annotations at different points of a pipeline, so the module stays a SINGLE
# rule and the workflow instantiates it as many times as needed, each with its own
# input project and config block:
#
#   use rule statistics_annotation as blast2go_annotation_charts with:
#       input: project=rules.go_annotation.output.project;   output: directory(...)
#       params: chart_format=CHART_FORMAT, args=join_args("blast2go_annotation_charts")
#   use rule statistics_annotation as final_annotation_charts with: ...
#   use rule statistics_annotation as goslim_annotation_charts with: ...


rule statistics_annotation:
    shell:
        r"""
        (
            mkdir -p {output}
            omicsbox statistics-annotation \
                --i-project="{input.project}" \
                --chart-format={params.chart_format} \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
