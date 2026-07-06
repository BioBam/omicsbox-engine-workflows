// --- FILE: modules/pilon.nf ---
// Wraps: omicsbox pilon  |  backend: LEGACY_SYNC
// Polishes long-read assembly using short-read alignments.
nextflow.enable.dsl=2

process PILON {

    input:
    path assembly               // Unpolished long-read assembly (FASTA)
    path bam_file               // Sorted BAM file from BWA alignment

    output:
    path "${task.ext.outdir}/*polished*.fasta", emit: polished_assembly   // Polished assembly (FASTA)
    path "${task.ext.outdir}/*report*.box", emit: report                  // OmicsBox report
    path "${task.ext.outdir}/*chart*.${params.chart_format}", emit: chart  // OmicsBox chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // LEGACY_SYNC

    """
    mkdir -p ${outdir}
    omicsbox pilon \\
        --i-assembly=\$PWD/${assembly} \\
        --i-bam-file=\$PWD/${bam_file} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
