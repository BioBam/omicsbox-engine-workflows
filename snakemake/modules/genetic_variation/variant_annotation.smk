# --- FILE: modules/genetic_variation/variant_annotation.smk ---
# Wraps: omicsbox variant-annotation - annotates VCF variants with their functional
# effects, using a genome and its annotation.
#
# Generic, reusable rule (operation = `variant_annotation`). Instantiate with:
#
#   use rule variant_annotation as <step> with:
#       input:
#           vcf=<VCF with the variants to annotate>,
#           annotation=<annotation GTF matching the genome species and version>,
#           genome=<genome FASTA, the same one used for variant calling>,
#       output:
#           table=os.path.join(stage("<step>"), "Variant_Annotation_Table.box"),
#           report=os.path.join(stage("<step>"), "Variant_Annotation_Report.box"),
#       params:
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Both output names are fixed, so they are declared exactly and no renaming is needed.
# A pie chart of the annotated variant types is written into the same folder and left
# undeclared: this step is not given a chart-format setting, so the chart comes out in
# the tool's own default format rather than the one configured for the pipeline, and
# declaring it would tie the step to an assumption about that default.


rule variant_annotation:
    shell:
        r"""
        (
            omicsbox variant-annotation \
                --i-vcf-file="{input.vcf}" \
                --i-annotation="{input.annotation}" \
                --i-genome="{input.genome}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
