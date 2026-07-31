# --- FILE: modules/export_annotations/export_genesets.smk ---
# Wraps: omicsbox export-genesets - exports annotated gene sets (terminal step).
#
# Generic, reusable rule (operation = `export_genesets`). No --chart-format.
# Instantiate with:
#   use rule export_genesets as <step> with:
#       input:  project=<upstream project box>
#       output: genesets=<step>/file.txt
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")
#
# Writes ONE TSV, not a folder: the name comes from the CLI parameter id
# (`ExportGeneSetsParameters.file`, kebab of `file` + the `*.txt` filter) -> literally
# `file.txt`. See OUTPUT_FILENAMES.md section 3. Declared as an exact file output, so no
# mkdir is needed (Snakemake pre-creates the parent = --local-folder) and a step that
# silently produces nothing fails with MissingOutputException instead of passing.


rule export_genesets:
    shell:
        r"""
        (
            omicsbox export-genesets \
                --i-project="{input.project}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
