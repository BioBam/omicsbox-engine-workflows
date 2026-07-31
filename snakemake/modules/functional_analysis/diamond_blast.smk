# --- FILE: modules/functional_analysis/diamond_blast.smk ---
# Wraps: omicsbox diamond - sequence similarity search via DIAMOND BLAST.
#
# Generic, reusable rule (operation = `diamond`). Instantiate with:
#   use rule diamond as <step> with:
#       input:  project=<upstream project box>
#       output: project=<step>/diamond_output_project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")
#
# `{params.outdir}` (the parent of the declared output) is what OmicsBox writes
# into; Snakemake pre-creates it, so no mkdir is needed. Output goes to {log}.


rule diamond:
    shell:
        r"""
        (
            omicsbox diamond \
                --i-local-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
