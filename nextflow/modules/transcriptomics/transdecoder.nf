// --- FILE: modules/transcriptomics/transdecoder.nf ---
// Wraps: omicsbox transdecoder
// Predicts protein-coding regions (ORFs) in assembled transcripts.

process TRANSDECODER {

    input:
    path fasta                  // Transcript sequences FASTA
    path gene_trans_map          // Optional: transcript-to-gene ID map

    output:
    path "${task.ext.outdir}/protein-output.fasta", emit: predicted_proteins  // Predicted proteins FASTA
    path "${task.ext.outdir}/cds-output.fasta", emit: predicted_cds           // Predicted CDS FASTA
    path "${task.ext.outdir}/output-gff.gff", emit: gff                       // Predicted ORFs in GFF
    path "${task.ext.outdir}/*report*.box", emit: report                      // TransDecoder report
    path "${task.ext.outdir}/*chart*.box", emit: chart     // TransDecoder chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // Optional-input convention: when no gene-trans-map file is wired in, the workflow passes an
    // empty List (channel.value([])) instead of a real path - that's the "not provided" case to skip.
    def gene_trans_map_flag = (!(gene_trans_map instanceof List) || !gene_trans_map.isEmpty())
        ? "--provide-gene-trans-map=true --i-gene-trans-map=\$PWD/${gene_trans_map}"
        : "--provide-gene-trans-map=false"

    """
    mkdir -p ${outdir}
    omicsbox transdecoder \\
        --i-input=\$PWD/${fasta} \\
        ${gene_trans_map_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
