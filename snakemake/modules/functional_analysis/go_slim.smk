# --- FILE: modules/functional_analysis/go_slim.smk ---
# Wraps: omicsbox goslim - generates a GO-Slim subset annotation.
#
# Generic, reusable rule (operation = `goslim`). Instantiate with:
#   use rule goslim as <step> with:
#       input:  project=<upstream project box>, obo=<[] or [custom OBO file]>
#       output: project=<step>/project.box
#       params: outdir=stage("<step>"), obo_flag=<"" or --i-go-slim-obo-file=...>,
#               args=join_args("<step>")
#       log:    logfile("<step>")
#
# Optional-input convention: the workflow passes an EMPTY LIST for `input.obo` when
# no custom OBO file is configured, and `params.obo_flag` is then the empty string,
# so the CLI call simply omits --i-go-slim-obo-file. Only takes effect when args also
# sets --option=custom (which disables --go-slim-web-file).


rule goslim:
    shell:
        r"""
        (
            omicsbox goslim \
                --i-project="{input.project}" \
                {params.obo_flag} \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
