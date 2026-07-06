// --- FILE: modules/flye.nf ---
// Wraps: omicsbox flye  |  backend: LEGACY_SYNC
// Long-read de novo genome assembly using Flye.
nextflow.enable.dsl=2

process FLYE {

    input:
    path reads                      // Trimmed long reads (List of FASTQ/FASTA files)

    output:
    path "${task.ext.outdir}/*assembly*.fasta", emit: assembly        // De novo assembled genome (FASTA)
    path "${task.ext.outdir}/*report*.box", emit: report              // OmicsBox report
    path "${task.ext.outdir}/*chart*.${params.chart_format}", emit: chart, optional: true    // OmicsBox chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // =====================================================================
    // DYNAMIC: Library type flag injection
    // Maps library_type parameter to OmicsBox CLI flag
    // =====================================================================
    def lib_type = params.flye.library_type ?: 'pacbio_raw'
    def lib_flag = [
        'pacbio_raw': '--i-pacbio-raw',
        'pacbio_corr': '--i-pacbio-corr',
        'nano_raw': '--i-nano-raw',
        'nano_corr': '--i-nano-corr'
    ][lib_type]

    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    // LEGACY_SYNC

    """
    mkdir -p ${outdir}
    omicsbox flye \\
        ${lib_flag}=${reads_list} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
