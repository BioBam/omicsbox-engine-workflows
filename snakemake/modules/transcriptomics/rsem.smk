# --- FILE: modules/transcriptomics/rsem.smk ---
# Wraps: omicsbox rsem - transcript/gene-level expression quantification (RSEM)
# against a reference transcriptome assembly.
#
# Generic, reusable rule (operation = `rsem`). Self-contained: the SE/PE branch,
# comma-joining, and accepting either a literal FASTQ file list or a directory output
# all live in the shell - see fastqc.smk /
# trimmomatic.smk for the same pattern. Instantiate with:
#
#   use rule rsem as <step> with:
#       input:
#           reads=<one or many FASTQ, or an upstream directory(...) output>,
#           assembly=<reference transcriptome FASTA>,
#           gene_trans_map=<transcript-to-gene file or []>,   # [] = not provided
#       output:
#           counts=os.path.join(stage("<step>"), "<the count table the statistics steps read>"),
#           report=os.path.join(stage("<step>"), "transcript_quantification_report.box"),
#       params:
#           single_end="true" if config["input_single_end"] else "false",
#           up_pattern=config.get("upstream_pattern", "_1"),
#           down_pattern=config.get("downstream_pattern", "_2"),
#           gene_level="true" / "false",
#           gtm_flag=<"" or --i-transcript-to-gene-file=...>,
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Two count tables, two regimes:
#   transcript_quantification_isoforms.box   always written, fixed name
#   transcript_quantification_genes.box      only with --gene-level=true, fixed name
# Gene-level estimates are the sum of each gene's isoform estimates, so the tool needs
# the transcript-to-gene map to know which isoform belongs to which gene; without it
# every reference sequence is its own gene and the gene table just repeats the isoform
# one. That is why `gtm_flag` is only set when gene level is on.
#
# The report is a third regime: it comes out with a per-run suffix
# (`transcript_quantification_report_<id>_<date>_<6 random chars>.box`) whose tail is
# random, so the rule resolves it by glob and renames it to the stable name declared
# above. A per-sample BAM (--bam-output=true) stays in the folder untracked.


rule rsem:
    shell:
        r"""
        (
            if [ -d "{input.reads}" ]; then
                reads=$(find "{input.reads}" -maxdepth 1 -type f \( -name '*.fastq' -o -name '*.fastq.gz' -o -name '*.fq' -o -name '*.fq.gz' \) | sort | tr '\n' ',' | sed 's/,$//')
            else
                reads=$(echo {input.reads} | tr ' ' ',')
            fi

            if [ "{params.single_end}" = "true" ]; then
                input_flag="--i-fastq-files-single-end=$reads"
                pattern_flags=""
            else
                input_flag="--i-fastq-files-paired-end=$reads"
                pattern_flags="--upstream-pattern-counts={params.up_pattern} --downstream-pattern-counts={params.down_pattern}"
            fi

            mkdir -p "{params.outdir}"
            omicsbox rsem \
                --i-fasta-file="{input.assembly}" \
                --gene-level={params.gene_level} \
                {params.gtm_flag} \
                $input_flag \
                $pattern_flags \
                --local-folder="{params.outdir}" \
                {params.args}

            # The report name carries an unpredictable per-run suffix; resolve and rename it.
            mv "$(find "{params.outdir}" -maxdepth 1 -name 'transcript_quantification_report_*.box' | head -n1)" "{output.report}"
        ) >{log} 2>&1
        """
