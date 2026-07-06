// --- FILE: modules/longqc.nf ---
// Wraps: omicsbox longqc  |  backend: LEGACY_SYNC
// Quality control and trimming for long-read sequencing data.
nextflow.enable.dsl=2

process LONGQC {

    input:
    path reads                      // Long reads (List of FASTQ/FASTA files)

    output:
    path "${task.ext.outdir}/*trimmed*", emit: trimmed_reads          // Trimmed/filtered long reads
    path "${task.ext.outdir}/*report*.box", emit: report              // OmicsBox QC report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    // LEGACY_SYNC

    """
    mkdir -p ${outdir}
    omicsbox longqc \\
        --i-reads=${reads_list} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
