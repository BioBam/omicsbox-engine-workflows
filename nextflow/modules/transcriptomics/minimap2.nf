// --- FILE: modules/transcriptomics/minimap2.nf ---
// Wraps: omicsbox minimap2
// Maps long reads (PacBio/ONT) to a reference genome using Minimap2.

process MINIMAP2 {

    input:
    path long_reads   // FASTA/Q long reads to map (one or more files)
    path ref_genome   // Reference genome FASTA
    path junc_bed     // Optional: junction BED/GTF/BAM file (enables --use-junc-bed)

    output:
    path "${task.ext.outdir}/*.bam", emit: bam                          // Aligned reads BAM, one per sample
    path "${task.ext.outdir}/minimap2_report.box", emit: report          // Alignment report
    path "${task.ext.outdir}/minimap2_chart_abs.box", emit: chart_abs    // Absolute-value chart
    path "${task.ext.outdir}/minimap2_chart_rel.box", emit: chart_rel    // Relative-value chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // 'long_reads' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def reads_list = long_reads instanceof List
        ? long_reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${long_reads}"

    // Optional-input convention: when no junction BED is wired in, the workflow passes an empty
    // List (channel.value([])) instead of a real path - that's the "not provided" case to skip.
    def junc_flag = (!(junc_bed instanceof List) || !junc_bed.isEmpty())
        ? "--i-junc-bed=\$PWD/${junc_bed}"
        : ""

    """
    mkdir -p ${outdir}
    omicsbox minimap2 \\
        --i-long-reads=${reads_list} \\
        --i-ref-genome=\$PWD/${ref_genome} \\
        ${junc_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
