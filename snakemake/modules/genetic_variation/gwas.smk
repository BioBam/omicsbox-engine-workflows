# --- FILE: modules/genetic_variation/gwas.smk ---
# Wraps: omicsbox gwas - tests association between genotypes in a VCF and phenotypic
# traits.
#
# Generic, reusable rule (operation = `gwas`). Instantiate with:
#
#   use rule gwas as <step> with:
#       input:
#           vcf=<VCF with the SNPs to test>,
#           pheno=<traits table; sample names in the first column, header required>,
#           kinship=<kinship matrix or []>,
#           covariate=<covariate matrix or []>,
#       output:
#           results=os.path.join(stage("<step>"), "gwas_results.box"),
#           report=os.path.join(stage("<step>"), "gwas_report.box"),
#       params:
#           outdir=stage("<step>"),
#           kinship_flag=<"" or --i-kinship=...>,
#           covariate_flag=<"" or --i-covariate-matrix=...>,
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# The results project and the report are the two guaranteed outputs and have fixed
# names, so they are declared exactly.
#
# Two more files can land in an `output/` sub-folder inside the step directory:
# a normalized phenotype table (written whenever phenotype normalization or outlier
# removal is on) and a covariate matrix (written only with the covariate matrix
# enabled). Both are left undeclared - each depends on a switch the user can flip, the
# phenotype table's extension also varies with whether it ends up compressed, and
# nothing downstream reads either of them.
#
# Both matrix inputs are optional and each is paired with a switch in `args`: a matrix
# is only read when its switch is on, and turning a switch on without supplying the
# matrix leaves the step with nothing to read - so the two have to agree.


rule gwas:
    shell:
        r"""
        (
            omicsbox gwas \
                --i-input-vcf="{input.vcf}" \
                --i-input-pheno="{input.pheno}" \
                {params.kinship_flag} \
                {params.covariate_flag} \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
