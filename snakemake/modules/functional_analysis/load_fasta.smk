# --- FILE: modules/functional_analysis/load_fasta.smk ---
# Wraps: omicsbox load-sequences - loads FASTA sequences into an OmicsBox project.
#
# Generic, reusable rule (operation = `load_sequences`). Instantiate it at any
# workflow step with:
#   use rule load_sequences as <step> with:
#       input:  fasta=<input FASTA>
#       output: project=<step>/project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")


rule load_sequences:
    shell:
        r"""
        (
            omicsbox load-sequences \
                --i-file="{input.fasta}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
