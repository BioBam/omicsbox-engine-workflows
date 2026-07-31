# --- FILE: modules/genome_analysis/bwa.smk ---
# Wraps: omicsbox bwa - aligns short reads to a genome assembly, producing
# coordinate-sorted BAM alignments.
#
# Generic, reusable rule (operation = `bwa`). Self-contained: the SE/PE branch,
# comma-joining, and accepting either a literal FASTQ file list or a directory output
# all live in the shell - see fastqc.smk / trimmomatic.smk for the same pattern.
# Instantiate with:
#
#   use rule bwa as <step> with:
#       input:
#           reference=<genome assembly FASTA>,
#           reads=<one or many FASTQ, or an upstream directory(...) output>,
#       output:
#           directory(stage("<step>")),
#       params:
#           single_end="true" if config["input_single_end"] else "false",
#           up_pattern=config.get("upstream_pattern", "_1"),
#           down_pattern=config.get("downstream_pattern", "_2"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Everything lands in ONE folder, which is why the whole stage folder is the output
# (needs `mkdir -p` first - Snakemake does not pre-create a directory() output):
#
#   <step>/*.bam                 coordinate-sorted alignment, one per sample
#   <step>/bwa_report.box        report
#   <step>/bwa_chart_abs.box     absolute-value chart
#   <step>/bwa_chart_rel.box     relative-value chart
#
# The BAM filenames are chosen per sample by the aligner, so a consumer globs `*.bam`
# rather than taking the folder wholesale.
#
# The read-pair pattern flags are plain `--upstream-pattern`/`--downstream-pattern`
# here; other read-consuming tools spell the same idea with a tool-specific suffix, so
# they are not interchangeable.


rule bwa:
    shell:
        r"""
        (
            mkdir -p {output}

            # input.reads is either a directory (glob its root for FASTQ files,
            # non-recursive) or a Snakemake space-separated file list; OmicsBox wants commas.
            if [ -d "{input.reads}" ]; then
                reads=$(find "{input.reads}" -maxdepth 1 -type f \( -name '*.fastq' -o -name '*.fastq.gz' -o -name '*.fq' -o -name '*.fq.gz' \) | sort | tr '\n' ',' | sed 's/,$//')
            else
                reads=$(echo {input.reads} | tr ' ' ',')
            fi

            if [ "{params.single_end}" = "true" ]; then
                input_flag="--i-input-sequencing-data-single-end=$reads"
                pattern_flags=""
            else
                input_flag="--i-input-sequencing-data-paired-end=$reads"
                pattern_flags="--upstream-pattern={params.up_pattern} --downstream-pattern={params.down_pattern}"
            fi

            omicsbox bwa \
                --i-fasta-file="{input.reference}" \
                $input_flag \
                $pattern_flags \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
