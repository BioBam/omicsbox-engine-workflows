# --- FILE: modules/metagenomics/pfam_scan.smk ---
# Wraps: omicsbox pfam-scan - annotates sequences with Pfam protein domains.
#
# Generic, reusable rule (operation = `pfam_scan`). Instantiate with:
#
#   use rule pfam_scan as <step> with:
#       input:
#           fasta=<protein or nucleotide FASTA>,
#       output:
#           annotations=os.path.join(stage("<step>"), "PfamScan_Annotations.box"),
#           report=os.path.join(stage("<step>"), "PfamScan_Report.box"),
#       params:
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Both output names are fixed, so they are declared exactly and no renaming is needed.
# Note the mixed case and underscore: they are written exactly as spelled above.


rule pfam_scan:
    shell:
        r"""
        (
            omicsbox pfam-scan \
                --i-sequences="{input.fasta}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
