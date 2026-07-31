# --- FILE: modules/metagenomics/megahit.smk ---
# Wraps: omicsbox megahit - de novo metagenome assembly from sequencing reads.
#
# Generic, reusable rule (operation = `megahit`). Self-contained: the SE/PE branch and
# accepting either a literal FASTQ file list or a directory output live in the shell.
# Instantiate with:
#
#   use rule megahit as <step> with:
#       input:
#           reads=<one or many FASTQ, or an upstream directory(...) output>,
#       output:
#           contigs=os.path.join(stage("<step>"), "megahit-contigs.fasta"),
#           report=os.path.join(stage("<step>"), "megahit_report.box"),
#           nx_plot=os.path.join(stage("<step>"), f"nx-plot.{CHART_FORMAT}"),
#       params:
#           single_end="true" if config["input_single_end"] else "false",
#           up_pattern=config.get("upstream_pattern", "_1"),
#           down_pattern=config.get("downstream_pattern", "_2"),
#           reads_glob="<glob>",          # which files to take when reads is a directory
#           chart_format=CHART_FORMAT,
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# All three output names are fixed, so they are declared exactly and no renaming is
# needed. `nx-plot` is named after its chart title, so its extension follows the
# configured chart format.
#
# TWO details that differ from the other read-consuming tools:
#
#  * The reads are passed as ONE REPEATED FLAG PER FILE (`--i-read-files=a
#    --i-read-files=b`) rather than as a single comma-joined value.
#  * `params.reads_glob` is supplied by the caller instead of being hardcoded, because
#    an upstream folder may hold more read sets than the one to assemble. A
#    decontamination step, for instance, can leave both the clean and the contaminant
#    reads side by side, and assembling the wrong set fails silently - the run
#    succeeds, the contigs are just wrong.
#
# The read-pair pattern flags are plain `--upstream-pattern`/`--downstream-pattern`
# here; other read-consuming tools spell the same idea with a tool-specific suffix, so
# they are not interchangeable.


rule megahit:
    shell:
        r"""
        (
            # One --i-read-files flag per file. input.reads is either a directory
            # (glob its root, non-recursive) or a Snakemake space-separated file list.
            if [ -d "{input.reads}" ]; then
                read_flags=$(find "{input.reads}" -maxdepth 1 -type f -name '{params.reads_glob}' | sort | sed 's|^|--i-read-files=|' | tr '\n' ' ')
            else
                read_flags=""
                for f in {input.reads}; do
                    read_flags="$read_flags --i-read-files=$f"
                done
            fi

            if [ "{params.single_end}" = "true" ]; then
                seq_flag="--sequencing=single"
                pattern_flags=""
            else
                seq_flag="--sequencing=paired"
                pattern_flags="--upstream-pattern={params.up_pattern} --downstream-pattern={params.down_pattern}"
            fi

            omicsbox megahit \
                $seq_flag \
                $read_flags \
                $pattern_flags \
                --chart-format="{params.chart_format}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
