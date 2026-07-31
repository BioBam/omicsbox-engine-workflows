# --- FILE: modules/functional_analysis/go_mapping.smk ---
# Wraps: omicsbox mapping-cloud - maps sequences to Gene Ontology terms.
#
# Generic, reusable rule (operation = `mapping_cloud`). Instantiate with:
#   use rule mapping_cloud as <step> with:
#       input:  project=<upstream project box>
#       output: project=<step>/project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")


rule mapping_cloud:
    shell:
        r"""
        (
            omicsbox mapping-cloud \
                --i-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
