# --- FILE: modules/functional_analysis/ips.smk ---
# Wraps: omicsbox ips - protein domain annotation via InterProScan.
#
# Generic, reusable rule (operation = `ips`). Instantiate with:
#   use rule ips as <step> with:
#       input:  project=<upstream project box>
#       output: project=<step>/cloud_ips_output_project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")
# Any export files (xml/gff3/tsv, per --export-format) are left next to the
# project inside the stage folder (untracked - their names are unpredictable).


rule ips:
    shell:
        r"""
        (
            omicsbox ips \
                --i-local-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
