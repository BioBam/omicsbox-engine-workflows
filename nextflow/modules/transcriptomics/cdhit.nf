// --- FILE: modules/transcriptomics/cdhit.nf ---
// Wraps: omicsbox cdhit
// Clusters transcript sequences by sequence identity to remove redundancy.

process CDHIT {

    input:
    path assembly   // Assembled transcripts FASTA

    output:
    path "${task.ext.outdir}/output.fasta", emit: clustered_fasta          // Non-redundant representative sequences
    path "${task.ext.outdir}/output-clusters.txt", emit: clusters, optional: true  // Cluster membership file (only if --save-clusters=true)
    path "${task.ext.outdir}/*report*.box", emit: report                   // CD-HIT report
    path "${task.ext.outdir}/*chart*.${params.chart_format}", emit: chart  // CD-HIT chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''


    """
    mkdir -p ${outdir}
    omicsbox cdhit \\
        --i-input=\$PWD/${assembly} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
