// --- FILE: modules/metagenomics/cont_rem.nf ---
// Wraps: omicsbox cont-rem
// Removes contaminant reads (e.g. host/human DNA) from metagenomic libraries.

process CONT_REM {

    input:
    path reads          // Input reads (single-end or paired-end, List of FASTQ files)
    path target_genome  // Optional: custom target genome FASTA

    output:
    path "${task.ext.outdir}/un_*.fq.gz", emit: clean_reads, optional: true                  // Contaminant-free (unaligned) reads, when result-mode includes unaligned
    path "${task.ext.outdir}/al_*.fq.gz", emit: contaminant_reads, optional: true            // Contaminant (aligned) reads, when result-mode includes aligned
    path "${task.ext.outdir}/*report*.box", emit: report                                     // Decontamination report
    path "${task.ext.outdir}/*chart_abs*.box", emit: chart_abs            // Absolute-value chart
    path "${task.ext.outdir}/*chart_rel*.box", emit: chart_rel            // Relative-value chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // 'reads' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = is_single_end
        ? "--sequencing=fastq_se --i-read-files-single-end=${reads_list}"
        : "--sequencing=fastq_pe --i-read-files-paired-end=${reads_list}"

    def pattern_flags = ""

    // Only paired-end needs these: they tell OmicsBox how to pair up R1/R2 files by name
    // (e.g. '_1'/'_2') when multiple sample pairs are collected into the same run.
    if (!is_single_end) {
        def up_pat = params.getOrDefault('upstream_pattern', '_1')
        def down_pat = params.getOrDefault('downstream_pattern', '_2')
        pattern_flags = "--upstream-pattern-preprocessing=${up_pat} --downstream-pattern-preprocessing=${down_pat}"
    }

    // Optional-input convention: when no custom target genome is wired in, the workflow passes an
    // empty List (channel.value([])) instead of a real path - that's the "not provided" case to skip.
    def target_flag = (!(target_genome instanceof List) || !target_genome.isEmpty())
        ? "--i-target-genome=\$PWD/${target_genome}"
        : ""


    """
    mkdir -p ${outdir}
    omicsbox cont-rem \\
        ${input_flag} \\
        ${pattern_flags} \\
        ${target_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
