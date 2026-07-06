// --- FILE: modules/metagenomics/megahit.nf ---
// Wraps: omicsbox megahit  |  backend: WJOB_ASYNC
// De novo metagenome assembly using MEGAHIT.
nextflow.enable.dsl=2

process MEGAHIT {

    input:
    path reads                  // Contaminant-free reads (single-end or paired-end, List of FASTQ files)

    output:
    path "${task.ext.outdir}/*contigs*.fasta", emit: contigs         // Assembled contigs FASTA file
    path "${task.ext.outdir}/*report*.box", emit: report             // OmicsBox report
    path "${task.ext.outdir}/*chart*.${params.chart_format}", emit: chart  // OmicsBox chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // =====================================================================
    // DYNAMIC: Single-End vs Paired-End input flag
    // Metagenomics typically uses paired-end, but single-end is supported
    // =====================================================================
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = is_single_end
        ? "--i-input-sequencing-data-single=${reads_list}"
        : "--i-input-sequencing-data-paired=${reads_list}"

    // =====================================================================
    // DYNAMIC: Paired-end pattern flags (only if paired-end input)
    // =====================================================================
    def pattern_flags = ""
    if (!is_single_end) {
        def up_pat = params.keySet().contains('upstream_pattern') && params.upstream_pattern ? params.upstream_pattern : '_1'
        def down_pat = params.keySet().contains('downstream_pattern') && params.downstream_pattern ? params.downstream_pattern : '_2'
        pattern_flags = "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
    }

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    xvfb-run -a omicsbox megahit \\
        ${input_flag} \\
        ${pattern_flags} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
