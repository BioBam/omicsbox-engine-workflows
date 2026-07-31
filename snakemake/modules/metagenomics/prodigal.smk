# --- FILE: modules/metagenomics/prodigal.smk ---
# Wraps: omicsbox prodigal - predicts protein-coding genes in prokaryotic or
# metagenomic contigs.
#
# Generic, reusable rule (operation = `prodigal`). Instantiate with:
#
#   use rule prodigal as <step> with:
#       input:
#           contigs=<assembled contigs FASTA>,
#       output:
#           proteins=os.path.join(stage("<step>"), "faa.fasta"),
#           genes=os.path.join(stage("<step>"), "fna.fasta"),
#           gff=os.path.join(stage("<step>"), "gff.gff"),
#           report=os.path.join(stage("<step>"), "prodigal_report.box"),
#           gc_chart=os.path.join(stage("<step>"), f"gc-content-distribution.{CHART_FORMAT}"),
#           length_chart=os.path.join(stage("<step>"), f"gene-length-distribution.{CHART_FORMAT}"),
#       params:
#           outdir=stage("<step>"),
#           chart_format=CHART_FORMAT,
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# The names above are all fixed, so they are declared exactly and no renaming is needed.
# `faa.fasta` holds the predicted proteins and `fna.fasta` the same genes as
# nucleotides, so a downstream annotation step picks whichever it needs. The two
# distribution charts are named after their chart titles, so their extension follows
# the configured chart format.
#
# A `prodigal_log.box` may also appear in the folder. It is left undeclared: nothing
# downstream reads it, and declaring an output that turns out not to be written would
# fail the step.


rule prodigal:
    shell:
        r"""
        (
            omicsbox prodigal \
                --i-sequences="{input.contigs}" \
                --chart-format="{params.chart_format}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
