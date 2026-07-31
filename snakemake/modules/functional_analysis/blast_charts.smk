# --- FILE: modules/functional_analysis/blast_charts.smk ---
# Wraps: omicsbox statistics-blast - DIAMOND BLAST charts (terminal step).
#
# Generic, reusable rule (operation = `statistics_blast`). Instantiate with:
#   use rule statistics_blast as <step> with:
#       input:  project=<upstream project box>
#       output: directory(<step folder>)
#       params: chart_format=CHART_FORMAT, args=join_args("<step>")
#       log:    logfile("<step>")
#
# The output is a directory(): Snakemake does NOT pre-create it, so mkdir it
# first (this is why chart rules carry a mkdir and project rules do not).


rule statistics_blast:
    shell:
        r"""
        (
            mkdir -p {output}
            omicsbox statistics-blast \
                --i-project="{input.project}" \
                --chart-format={params.chart_format} \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
