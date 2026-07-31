// --- FILE: modules/genome_analysis/bwa.nf ---
// Wraps: omicsbox bwa
// Aligns short reads to a genome assembly, producing coordinate-sorted BAM alignments.

process BWA {

    input:
    path reference              // Genome assembly FASTA file to align against
    path reads                  // Short reads (SE or PE, List of FASTQ files)

    output:
    path "${task.ext.outdir}/*.bam", emit: sorted_bam                              // Coordinate-sorted BAM alignment file
    path "${task.ext.outdir}/*report*.box", emit: report                          // BWA report
    path "${task.ext.outdir}/*chart_abs*.box", emit: chart_abs  // Absolute-value chart
    path "${task.ext.outdir}/*chart_rel*.box", emit: chart_rel  // Relative-value chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = is_single_end
        ? "--i-input-sequencing-data-single-end=${reads_list}"
        : "--i-input-sequencing-data-paired-end=${reads_list}"

    // Paired-end pattern flags tell OmicsBox how to pair up R1/R2 files by name
    def pattern_flags = ""
    if (!is_single_end) {
        def up_pat = params.getOrDefault('upstream_pattern', '_1')
        def down_pat = params.getOrDefault('downstream_pattern', '_2')
        pattern_flags = "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
    }


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
