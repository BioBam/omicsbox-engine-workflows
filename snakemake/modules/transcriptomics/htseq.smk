# --- FILE: modules/transcriptomics/htseq.smk ---
# Wraps: omicsbox htseq - counts aligned reads per gene from BAM files and a genome
# annotation, producing a gene-level count table.
#
# Generic, reusable rule (operation = `htseq`). Self-contained: accepting either a
# literal BAM file list or an upstream directory() output lives in the shell.
# Instantiate with:
#
#   use rule htseq as <step> with:
#       input:
#           bams=<one or many BAM, or an upstream directory(...) output>,
#           gff=<genome annotation, GTF/GFF>,
#       output:
#           count_table=os.path.join(stage("<step>"), "count_table.box"),
#           report=os.path.join(stage("<step>"), "htseq_report.box"),
#       params:
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Both output names are fixed, so they are declared exactly and no renaming is needed.
#
# When `input.bams` is a directory, the glob is restricted to `*.bam`: an aligner's
# output folder also holds its report boxes and, depending on its settings, splice
# junction tables and unmapped reads, none of which are alignments.


rule htseq:
    shell:
        r"""
        (
            if [ -d "{input.bams}" ]; then
                bams=$(find "{input.bams}" -maxdepth 1 -type f -name '*.bam' | sort | tr '\n' ',' | sed 's/,$//')
            else
                bams=$(echo {input.bams} | tr ' ' ',')
            fi

            omicsbox htseq \
                --i-alignment-files="$bams" \
                --i-gff-file="{input.gff}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
