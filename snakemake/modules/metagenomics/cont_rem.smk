# --- FILE: modules/metagenomics/cont_rem.smk ---
# Wraps: omicsbox cont-rem - removes contaminant reads (e.g. host DNA) from a
# sequencing library by aligning against a target genome and keeping one side.
#
# Generic, reusable rule (operation = `cont_rem`). Self-contained: the SE/PE branch,
# comma-joining, and accepting either a literal FASTQ file list or a directory output
# all live in the shell - see fastqc.smk / trimmomatic.smk for the same pattern.
# Instantiate with:
#
#   use rule cont_rem as <step> with:
#       input:
#           reads=<one or many FASTQ, or an upstream directory(...) output>,
#           target=<target genome FASTA or []>,   # [] = use a built-in index instead
#       output:
#           directory(stage("<step>")),
#       params:
#           single_end="true" if config["input_single_end"] else "false",
#           up_pattern=config.get("upstream_pattern", "_1"),
#           down_pattern=config.get("downstream_pattern", "_2"),
#           target_flag=<"" or --i-target-genome=...>,
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Everything lands in ONE folder, which is why the whole stage folder is the output
# (needs `mkdir -p` first - Snakemake does not pre-create a directory() output):
#
#   <step>/un_*.fq.gz              reads that did NOT align: the decontaminated set
#   <step>/al_*.fq.gz              reads that DID align: the contaminants
#   <step>/cont_rem_report.box     report
#   <step>/cont_rem_chart_abs.box  absolute-value chart
#   <step>/cont_rem_chart_rel.box  relative-value chart
#
# Which of the two read sets is written depends on `--result-mode`, and both use one
# file per sample with a name the tool chooses. A consumer must therefore glob for the
# prefix it wants - `un_` for the clean reads - and never take the folder wholesale,
# or it may pick up the contaminants it was meant to discard.
#
# `--i-target-genome` is optional and paired with a choice in `--target-index`: it is
# only read when that flag asks for a database to be built from a supplied genome,
# rather than naming one of the built-in indexes.


rule cont_rem:
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
                input_flag="--sequencing=fastq_se --i-read-files-single-end=$reads"
                pattern_flags=""
            else
                input_flag="--sequencing=fastq_pe --i-read-files-paired-end=$reads"
                pattern_flags="--upstream-pattern-preprocessing={params.up_pattern} --downstream-pattern-preprocessing={params.down_pattern}"
            fi

            omicsbox cont-rem \
                $input_flag \
                $pattern_flags \
                {params.target_flag} \
                --local-folder="{output}" \
                {params.args}
        ) >{log} 2>&1
        """
