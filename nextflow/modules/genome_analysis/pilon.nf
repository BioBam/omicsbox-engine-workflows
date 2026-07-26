// --- FILE: modules/genome_analysis/pilon.nf ---
// Wraps: omicsbox pilon
// Polishes long-read assembly using short-read alignments.

process PILON {

    input:
    path assembly               // Unpolished long-read assembly (FASTA)
    path bam_file               // Sorted BAM alignment file

    output:
    path "${task.ext.outdir}/output-fasta.fasta", emit: polished_assembly                       // Polished assembly FASTA
    path "${task.ext.outdir}/output-changes.txt", emit: changes, optional: true                 // Applied changes list (only if --save-changes=true)
    path "${task.ext.outdir}/*report*.box", emit: report                                        // Pilon report
    path "${task.ext.outdir}/fix-type-distribution.${params.chart_format}", emit: fix_distribution  // Fix-type distribution chart
    path "${task.ext.outdir}/nx-plot.${params.chart_format}", emit: nx_plot                     // Nx plot chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''


    """
    mkdir -p ${outdir}
    omicsbox pilon \\
        --i-input-fasta=\$PWD/${assembly} \\
        --i-input-bams=\$PWD/${bam_file} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
