// --- FILE: modules/metagenomics/prodigal.nf ---
// Wraps: omicsbox prodigal  |  backend: LEGACY_SYNC
// Prokaryotic / metagenomic gene prediction from assembled contigs.
nextflow.enable.dsl=2

process PRODIGAL {

    input:
    path contigs   // Assembled metagenome contigs FASTA (from MEGAHIT)

    output:
    path "${task.ext.outdir}/*protein*.fasta", emit: proteins  // Predicted protein sequences (CDS translations)
    path "${task.ext.outdir}/*gene*.fasta", emit: genes        // Predicted gene (nucleotide) sequences
    path "${task.ext.outdir}/*report*.box", emit: report       // Gene prediction report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // LEGACY_SYNC — single input FASTA, absolute path enforced.
    """
    mkdir -p ${outdir}
    omicsbox prodigal \\
        --i-input-sequences=\$PWD/${contigs} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
