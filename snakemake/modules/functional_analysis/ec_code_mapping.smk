# --- FILE: modules/functional_analysis/ec_code_mapping.smk ---
# Wraps: omicsbox enzymecode - maps Enzyme Commission codes from GO annotations.
#
# Generic, reusable rule (operation = `enzymecode`). Instantiate with:
#   use rule enzymecode as <step> with:
#       input:  project=<upstream project box>
#       output: project=<step>/project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")


rule enzymecode:
    shell:
        r"""
        (
            omicsbox enzymecode \
                --i-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
