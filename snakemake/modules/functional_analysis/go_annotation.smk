# --- FILE: modules/functional_analysis/go_annotation.smk ---
# Wraps: omicsbox annotation - BLAST2GO functional annotation.
#
# Generic, reusable rule (operation = `annotation`). Instantiate with:
#   use rule annotation as <step> with:
#       input:  project=<upstream project box>
#       output: project=<step>/project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")


rule annotation:
    shell:
        r"""
        (
            omicsbox annotation \
                --i-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
