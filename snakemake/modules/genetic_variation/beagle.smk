# --- FILE: modules/genetic_variation/beagle.smk ---
# Wraps: omicsbox beagle - genotype phasing and imputation.
#
# Generic, reusable rule (operation = `beagle`). Instantiate with:
#
#   use rule beagle as <step> with:
#       input:
#           vcf=<VCF to phase and impute>,
#       output:
#           vcf=os.path.join(stage("<step>"), "out.vcf.gz"),
#           report=os.path.join(stage("<step>"), "Beagle_Report.box"),
#       params:
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Both output names are fixed, so they are declared exactly and no renaming is needed.


rule beagle:
    shell:
        r"""
        (
            omicsbox beagle \
                --i-gt="{input.vcf}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
