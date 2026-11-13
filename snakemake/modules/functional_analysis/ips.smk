# --- FILE: modules/functional_analysis/ips.smk ---
# Wraps: omicsbox interproscan - protein domain annotation via InterProScan.
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
            omicsbox interproscan \
                --i-local-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}

            # Async tools write each folder output into <local-folder>/<output-key>/; the
            # steps below and downstream rules expect those files at the top of the folder.
            find "{params.outdir}" -mindepth 2 -maxdepth 2 -type f -exec mv -n {{}} "{params.outdir}"/ \;
            find "{params.outdir}" -mindepth 1 -type d -empty -delete
        ) >{log} 2>&1
        """
