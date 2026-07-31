# --- FILE: modules/functional_analysis/combined_go_graph.smk ---
# Wraps: omicsbox graph-combined-make - combined GO graph (terminal step).
#
# Generic, reusable rule (operation = `graph_combined_make`). No --chart-format.
# Instantiate with:
#   use rule graph_combined_make as <step> with:
#       input:  project=<upstream project box>
#       output: directory(<step folder>)
#       params: args=join_args("<step>")
#       log:    logfile("<step>")


rule graph_combined_make:
    shell:
        r"""
        (
            mkdir -p {output}
            omicsbox graph-combined-make \
                --i-project="{input.project}" \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
