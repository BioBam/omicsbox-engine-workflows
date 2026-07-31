# --- FILE: modules/transcriptomics/star.smk ---
# Wraps: omicsbox star-aligner - aligns RNA-Seq reads to a reference genome.
#
# Generic, reusable rule (operation = `star_aligner`). Self-contained: the SE/PE
# branch, comma-joining, and accepting either a literal FASTQ file list or a
# directory output all live in the shell - see fastqc.smk / trimmomatic.smk for the
# same pattern. Instantiate with:
#
#   use rule star_aligner as <step> with:
#       input:
#           reads=<one or many FASTQ, or an upstream directory(...) output>,
#           fasta=<reference genome FASTA>,
#           annotation=<genome annotation, GTF/GFF - tracked as a dependency even if
#                       annotation_flag below ends up not using it>,
#       output:
#           directory(stage("<step>")),
#       params:
#           single_end="true" if config["input_single_end"] else "false",
#           up_pattern=config.get("upstream_pattern", "_1"),
#           down_pattern=config.get("downstream_pattern", "_2"),
#           annotation_flag=<"" or --provide-gff=true --i-annotation-file=...>,
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# `annotation_flag` carries BOTH halves together: the tool only accepts the annotation
# file paired with the switch that tells it to use it, so the two are built as one
# string and passed in or out as a unit rather than as two independently-toggled flags.
#
# Everything lands in ONE folder, which is why the whole stage folder is the output
# (needs `mkdir -p` first - Snakemake does not pre-create a directory() output):
#
#   <step>/*.bam                             alignment, one per sample (renamed - see below)
#   <step>/*_SJ.out.tab                      splice junctions, only when saved
#   <step>/*_Unmapped.fastq.gz               unmapped reads, only when saved
#   <step>/star_report.box                   report
#   <step>/chart_abs_value.box               absolute-value chart
#   <step>/chart_rel_value.box               relative-value chart
#
# The BAM/junction/unmapped-read filenames are chosen per sample by the aligner, and
# the three sets share this one folder, so a consumer must glob for the extension it
# wants (see htseq.smk, which globs `*.bam`) rather than taking the folder wholesale.
#
# The aligner names each BAM `<sample>_Aligned.sortedByCoord.out.bam` (or
# `<sample>_Aligned.out.bam` when coordinate sorting is off); the rule strips that
# suffix down to `<sample>.bam` right after the call, because the next step derives a
# sample's name by stripping only the `.bam` extension - left un-renamed, every sample
# would carry the aligner's suffix and never match a plain name in a design file.
#
# NOTE the read-pair pattern flags are plain `--upstream-pattern`/`--downstream-pattern`
# here; other read-consuming tools spell the same idea with a tool-specific suffix, so
# they are not interchangeable.


rule star_aligner:
    shell:
        r"""
        (
            mkdir -p {output}

            # input.reads is either a directory (glob its root for FASTQ files,
            # non-recursive - matches trimmomatic.smk's paired-reads-at-root layout)
            # or a Snakemake space-separated file list; OmicsBox wants commas.
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

            omicsbox star-aligner \
                $input_flag \
                $pattern_flags \
                --i-fasta-file="{input.fasta}" \
                {params.annotation_flag} \
                --local-folder="{output}" \
                {params.args}

            # Strip the aligner's own suffix down to a plain <sample>.bam - see the
            # header comment for why.
            for f in {output}/*_Aligned.sortedByCoord.out.bam {output}/*_Aligned.out.bam; do
                [ -e "$f" ] || continue
                mv "$f" "$(echo "$f" | sed -E 's/_Aligned(\.sortedByCoord)?\.out\.bam$/.bam/')"
            done
        ) >{log} 2>&1
        """
