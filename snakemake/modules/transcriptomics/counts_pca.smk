# --- FILE: modules/transcriptomics/counts_pca.smk ---
# Wraps: omicsbox counts-pca - PCA/PCoA visualization of sample distances from a
# count table.
#
# Generic, reusable rule (operation = `counts_pca`). Instantiate with:
#
#   use rule counts_pca as <step> with:
#       input:
#           count_table=<count table .box>,
#           design=<experimental design file or []>,   # [] = plot without the design
#       output:
#           chart=os.path.join(stage("<step>"), f"pca-plot.{CHART_FORMAT}"),
#       params:
#           outdir=stage("<step>"),
#           chart_format=CHART_FORMAT,
#           design_flag=<"" or --design=true --i-experimental-design=...>,
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# ONE chart, fixed name. The file is named after the chart title ("PCA Plot" ->
# `pca-plot.<chart_format>`), and the 2D and 3D variants share that title, so the
# name does not change with `--enable3d`. Declared as an exact file rather than a
# folder, so a run that produces nothing fails instead of passing silently.
#
# The design is optional here (it only colours the plot) and `params.design_flag`
# carries BOTH halves of it: `--design=true` and `--i-experimental-design=<file>`
# must be passed together or not at all, because the CLI rejects the file argument
# outright when `--design=false`. An empty flag means "plot without the design".


rule counts_pca:
    shell:
        r"""
        (
            mkdir -p "{params.outdir}"
            omicsbox counts-pca \
                --i-count-table="{input.count_table}" \
                {params.design_flag} \
                --chart-format="{params.chart_format}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
