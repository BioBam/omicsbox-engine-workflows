// --- FILE: modules/transcriptomics/star.nf ---
// Wraps: omicsbox star-aligner
// RNA-Seq read alignment to reference genome using STAR aligner.

process STAR {

    input:
    path reads                // Trimmed FASTQ reads (single-end or paired-end)
    path fasta                // Reference genome FASTA file
    path annotation           // Genome annotation in GTF/GFF format

    output:
    path "${task.ext.outdir}/*.bam", emit: bam_sorted                                    // Coordinate-sorted BAM(s), one per sample
    path "${task.ext.outdir}/*report*.box", emit: report                                 // STAR report
    path "${task.ext.outdir}/chart_abs_value.${params.chart_format}", emit: chart_abs    // Absolute-value chart
    path "${task.ext.outdir}/chart_rel_value.${params.chart_format}", emit: chart_rel    // Relative-value chart
    path "${task.ext.outdir}/*_SJ.out.tab", emit: splice_junctions, optional: true       // Splice junctions per sample (only if --save-splice-junctions=true)
    path "${task.ext.outdir}/*_Unmapped.fastq.gz", emit: unmapped_reads, optional: true  // Unmapped/partially-mapped reads per sample (only if --save-unmapped-reads=true)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    // A List of files looks the same whether it's several single-end samples or paired-end
    // mates, so the mode can't be inferred from 'reads' itself - it comes from the workflow param.
    def is_single_end = params.input_single_end ? true : false

    // 'reads' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"
    def input_flag = is_single_end
        ? "--i-input-sequencing-data-single-end=${reads_list}"
        : "--i-input-sequencing-data-paired-end=${reads_list}"

    // Pattern flags tell OmicsBox how to pair R1/R2 files by name (e.g. '_1'/'_2'); only
    // injected for paired-end runs when both patterns are actually configured in params.
    def up_pat   = params.getOrDefault('upstream_pattern', '_1')
    def down_pat = params.getOrDefault('downstream_pattern', '_2')
    def pattern_flags = (!is_single_end && up_pat && down_pat)
        ? "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
        : ""


    """
    mkdir -p ${outdir}
    omicsbox star-aligner \\
        ${input_flag} \\
        ${pattern_flags} \\
        --i-fasta-file=\$PWD/${fasta} \\
        --i-annotation-file=\$PWD/${annotation} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
