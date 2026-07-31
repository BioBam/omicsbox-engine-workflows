# --- FILE: modules/genetic_variation/bcftools.smk ---
# Wraps: omicsbox variantcalling-multipackage - calls SNPs and indels from BAM
# alignments against a reference genome (BCFtools).
#
# Generic, reusable rule (operation = `variantcalling_multipackage`). Self-contained:
# comma-joining and accepting either a literal BAM list or an upstream directory()
# output live in the shell. Instantiate with:
#
#   use rule variantcalling_multipackage as <step> with:
#       input:
#           bams=<one or many BAM, or an upstream directory(...) output>,
#           reference=<reference genome FASTA>,
#           group=<sample-to-group file or []>,
#       output:
#           vcf=os.path.join(stage("<step>"), "dir-save.vcf.gz"),
#           report=os.path.join(stage("<step>"), "Variant_Calling_Report.box"),
#       params:
#           outdir=stage("<step>"),
#           chart_format=CHART_FORMAT,
#           group_flag=<"" or --i-group-experiment=...>,
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# The VCF and the report are the two guaranteed outputs and have fixed names, so they
# are declared exactly. The read-depth and mapping-quality charts are written into the
# same folder but only when the corresponding chart was generated, so they are left
# undeclared - Snakemake treats every declared output as mandatory, and a conditional
# one would fail the step whenever it is absent.
#
# `--i-group-experiment` is optional and paired with a switch in `args`: it is only read
# when sample grouping is turned on, so the two have to agree.
#
# When `input.bams` is a directory, the glob is restricted to `*.bam`: an aligner's
# output folder also holds its report and chart boxes, which are not alignments.


rule variantcalling_multipackage:
    shell:
        r"""
        (
            if [ -d "{input.bams}" ]; then
                bams=$(find "{input.bams}" -maxdepth 1 -type f -name '*.bam' | sort | tr '\n' ',' | sed 's/,$//')
            else
                bams=$(echo {input.bams} | tr ' ' ',')
            fi

            omicsbox variantcalling-multipackage \
                --i-input-files="$bams" \
                --i-ref-gen="{input.reference}" \
                {params.group_flag} \
                --chart-format="{params.chart_format}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
