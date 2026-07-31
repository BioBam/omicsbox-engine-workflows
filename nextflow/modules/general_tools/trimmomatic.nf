// --- FILE: modules/general_tools/trimmomatic.nf ---
// Wraps: omicsbox trimmomatic
// Adapter and quality-based read trimming.

process TRIMMOMATIC {

    input:
    path reads      // Input FASTQ reads (single-end or paired-end)
    path adapters   // Optional: custom adapter FASTA file

    output:
    path "${task.ext.outdir}/*.fastq*", emit: trimmed_reads              // Trimmed paired-end reads
    path "${task.ext.outdir}/unpaired/unpaired_*.fastq*", emit: unpaired_reads, optional: true  // Unpaired reads (PE only)
    path "${task.ext.outdir}/*report*.box", emit: report                 // Trimming report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    // A List of files looks the same whether it's several single-end samples or paired-end
    // mates, so the mode can't be inferred from 'reads' itself - it comes from the workflow param.
    def is_single_end = params.input_single_end ? true : false

    // 'reads' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = is_single_end
        ? "--i-input-sequencing-data-furi-single-end=${reads_list}"
        : "--i-input-sequencing-data-furi-paired-end=${reads_list}"

    def pattern_flags = ""

    // Only paired-end needs these: they tell OmicsBox how to pair up R1/R2 files by name
    // (e.g. '_1'/'_2') when multiple sample pairs are collected into the same run.
    if (!is_single_end) {
        def up_pat = params.getOrDefault('upstream_pattern', '_1')
        def down_pat = params.getOrDefault('downstream_pattern', '_2')
        pattern_flags = "--upstream-pattern-preprocessing=${up_pat} --downstream-pattern-preprocessing=${down_pat}"
    }

    // Optional-input convention: when no adapter file is wired in, the workflow passes an empty
    // List (channel.value([])) instead of a real path - that's the "not provided" case to skip.
    def adapter_flag = (!(adapters instanceof List) || !adapters.isEmpty())
        ? "--i-adapter-file=\$PWD/${adapters}"
        : ""


    """
    mkdir -p ${outdir}
    omicsbox trimmomatic \\
        ${input_flag} \\
        ${pattern_flags} \\
        ${adapter_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}

    # Physically isolate unpaired files in a subfolder
    # The '2>/dev/null || true' prevents failure if no unpaired files exist (single-end reads)
    mkdir -p ${outdir}/unpaired
    mv ${outdir}/unpaired_*.fastq* ${outdir}/unpaired/ 2>/dev/null || true
    """
}