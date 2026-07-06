// --- FILE: modules/bwa.nf ---
// Wraps: omicsbox bwa  |  backend: LEGACY_SYNC
// Aligns short reads to long-read assembly reference for hybrid polishing.
nextflow.enable.dsl=2

process BWA {

    input:
    path reference              // Unpolished long-read assembly (FASTA from FLYE)
    path reads                  // Short reads (SE or PE, List of FASTQ files)

    output:
    path "${task.ext.outdir}/*.bam", emit: sorted_bam                 // Sorted BAM file
    path "${task.ext.outdir}/*report*.box", emit: report              // OmicsBox report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // =====================================================================
    // DYNAMIC: Single-End vs Paired-End input flag
    // Determines which CLI parameter to use based on input type
    // =====================================================================
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = is_single_end
        ? "--i-input-sequencing-data-single-end=${reads_list}"
        : "--i-input-sequencing-data-paired-end=${reads_list}"

    // =====================================================================
    // DYNAMIC: Paired-end pattern flags (only if paired-end input)
    // =====================================================================
    def pattern_flags = ""
    if (!is_single_end) {
        def up_pat = params.keySet().contains('upstream_pattern') && params.upstream_pattern ? params.upstream_pattern : '_1'
        def down_pat = params.keySet().contains('downstream_pattern') && params.downstream_pattern ? params.downstream_pattern : '_2'
        pattern_flags = "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
    }

    // LEGACY_SYNC

    """
    mkdir -p ${outdir}
    omicsbox bwa \\
        --i-fasta-file=\$PWD/${reference} \\
        ${input_flag} \\
        ${pattern_flags} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
