// --- FILE: modules/metagenomics/prodigal.nf ---
// Wraps: omicsbox prodigal
// Prokaryotic / metagenomic gene prediction from assembled contigs.

process PRODIGAL {

    input:
    path contigs   // Assembled metagenome contigs FASTA

    output:
    path "${task.ext.outdir}/faa.fasta", emit: proteins    // Predicted protein sequences
    path "${task.ext.outdir}/fna.fasta", emit: genes       // Predicted gene (nucleotide) sequences
    path "${task.ext.outdir}/gff.gff", emit: gff           // Gene coordinates (GFF)
    path "${task.ext.outdir}/*report*.box", emit: report   // Prodigal report
    path "${task.ext.outdir}/gc-content-distribution.${params.chart_format}", emit: gc_chart       // GC-content distribution chart
    path "${task.ext.outdir}/gene-length-distribution.${params.chart_format}", emit: length_chart  // Gene-length distribution chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox prodigal \\
        --i-sequences=\$PWD/${contigs} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
