// --- FILE: modules/load_fasta.nf ---
// Wraps: omicsbox load-sequences  |  backend: LEGACY_SYNC
// Loads FASTA sequences into an OmicsBox project for downstream annotation.
nextflow.enable.dsl=2

process LOAD_FASTA {

    input:
    path fasta_file     // Input FASTA file (assembled transcripts or proteins)

    output:
    path "${task.ext.outdir}/*", emit: fasta_project  // OmicsBox project directory

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox load-sequences \\
        --i-file=\$PWD/${fasta_file} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
