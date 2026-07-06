// --- FILE: modules/trimmomatic.nf ---
// Wraps: omicsbox trimmomatic  |  backend: WJOB_ASYNC
// Adapter and quality-based read trimming.
nextflow.enable.dsl=2

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
    def is_single_end = params.input_single_end ? true : false

    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = is_single_end
        ? "--i-input-sequencing-data-furi-single-end=${reads_list}"
        : "--i-input-sequencing-data-furi-paired-end=${reads_list}"

    def pattern_flags = ""

    if (!is_single_end) {
        def up_pat = params.keySet().contains('upstream_pattern') ? params.upstream_pattern : '_1'
        def down_pat = params.keySet().contains('downstream_pattern') ? params.downstream_pattern : '_2'
        pattern_flags = "--upstream-pattern-preprocessing=${up_pat} --downstream-pattern-preprocessing=${down_pat}"
    }

    def adapter_flag = (!(adapters instanceof List) || !adapters.isEmpty())
        ? "--i-adapter-file=\$PWD/${adapters}"
        : ""

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox trimmomatic \\
        ${input_flag} \\
        ${pattern_flags} \\
        ${adapter_flag} \\
        ${cloud_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}

    # Physically isolate unpaired files in a subfolder
    # The '2>/dev/null || true' prevents failure if no unpaired files exist (single-end reads)
    mkdir -p ${outdir}/unpaired
    mv ${outdir}/unpaired_*.fastq* ${outdir}/unpaired/ 2>/dev/null || true
    """
}