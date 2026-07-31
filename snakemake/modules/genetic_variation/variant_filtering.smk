# --- FILE: modules/genetic_variation/variant_filtering.smk ---
# Wraps: omicsbox variant-filtering-freebayes - filters a VCF by quality, depth,
# allele frequency and missingness criteria.
#
# Generic, reusable rule (operation = `variant_filtering_freebayes`). Instantiate with:
#
#   use rule variant_filtering_freebayes as <step> with:
#       input:
#           vcf=<VCF to filter>,
#       output:
#           vcf=os.path.join(stage("<step>"), "dir-save.vcf.gz"),
#           report=os.path.join(stage("<step>"), "Variant_Filtering_Report.box"),
#       params:
#           outdir=stage("<step>"),
#           chart_format=CHART_FORMAT,
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# The filtered VCF and the report are the two guaranteed outputs and have fixed names,
# so they are declared exactly. Several distribution charts are written into the same
# folder but only when the corresponding chart was generated, so they are left
# undeclared - Snakemake treats every declared output as mandatory, and a conditional
# one would fail the step whenever it is absent. One of them also has two possible
# names depending on which caller produced the incoming VCF, which is a second reason
# not to pin it.


rule variant_filtering_freebayes:
    shell:
        r"""
        (
            omicsbox variant-filtering-freebayes \
                --i-input-file="{input.vcf}" \
                --chart-format="{params.chart_format}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
