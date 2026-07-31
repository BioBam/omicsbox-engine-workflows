// --- FILE: modules/metagenomics/megahit.nf ---
// Wraps: omicsbox megahit
// De novo metagenome assembly using MEGAHIT.

process MEGAHIT {

    input:
    path reads                  // Input reads (single-end or paired-end, List of FASTQ files)

    output:
    path "${task.ext.outdir}/*contigs*.fasta", emit: contigs                 // Assembled contigs FASTA
    path "${task.ext.outdir}/*report*.box", emit: report                     // MEGAHIT report
    path "${task.ext.outdir}/nx-plot.${params.chart_format}", emit: nx_plot  // Nx plot chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // OmicsBox megahit expects one --i-read-files flag per file, repeated (not comma-joined).
    def input_flag = reads instanceof List
        ? reads.collect { file -> "--i-read-files=\$PWD/${file}" }.join(' ')
        : "--i-read-files=\$PWD/${reads}"

    def seq_flag = is_single_end ? "--sequencing=single" : "--sequencing=paired"

    def pattern_flags = ""
    // Only paired-end needs these: they tell OmicsBox how to pair up R1/R2 files by name
    // (e.g. '_1'/'_2') when multiple sample pairs are collected into the same run.
    if (!is_single_end) {
        def up_pat = params.getOrDefault('upstream_pattern', '_1')
        def down_pat = params.getOrDefault('downstream_pattern', '_2')
        pattern_flags = "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
    }


    """
    mkdir -p ${outdir}
    omicsbox megahit \\
        ${seq_flag} \\
        ${input_flag} \\
        ${pattern_flags} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
