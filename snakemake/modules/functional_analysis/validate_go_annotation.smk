# --- FILE: modules/functional_analysis/validate_go_annotation.smk ---
# Wraps: omicsbox annotation-validate - validates GO annotations (True-Path-Rule).
#
# Generic, reusable rule (operation = `annotation_validate`). Instantiate with:
#   use rule annotation_validate as <step> with:
#       input:  project=<upstream project box>
#       output: project=<step>/project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")


rule annotation_validate:
    shell:
        r"""
        (
            omicsbox annotation-validate \
                --i-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
