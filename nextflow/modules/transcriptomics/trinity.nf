// --- FILE: modules/transcriptomics/trinity.nf ---
// Wraps: omicsbox trinity
// De-novo RNA-Seq assembly.

process TRINITY {

    input:
    path reads   // Input FASTQ reads (single-end or paired-end)

    output:
    path "${task.ext.outdir}/transcripts.fasta", emit: assembly                                   // Assembled transcripts FASTA
    path "${task.ext.outdir}/save-map-file.txt", emit: gene_trans_map                             // Gene-to-transcript map
    path "${task.ext.outdir}/*assembly_report*.box", emit: report                                 // Trinity assembly report
    path "${task.ext.outdir}/super-transcripts.fasta", emit: supertranscripts, optional: true    // SuperTranscripts FASTA
    path "${task.ext.outdir}/super-transcripts-gff.gff", emit: supertranscripts_gff, optional: true  // SuperTranscripts GFF
    path "${task.ext.outdir}/*read_representation_report*.box", emit: read_content, optional: true   // Read-content object
    path "${task.ext.outdir}/trinity_relative_chart_*.box", emit: relative_chart, optional: true     // Read-representation chart, relative
    path "${task.ext.outdir}/trinity_absolute_chart_*.box", emit: absolute_chart, optional: true     // Read-representation chart, absolute

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // 'reads' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = is_single_end ? "--sequencing=Single" : "--sequencing=Paired"

    def pattern_flags = ""

    // Only paired-end needs these: they tell OmicsBox how to pair up R1/R2 files by name
    // (e.g. '_1'/'_2') when multiple sample pairs are collected into the same run.
    if (!is_single_end) {
        def up_pat = params.getOrDefault('upstream_pattern', '_1')
        def down_pat = params.getOrDefault('downstream_pattern', '_2')
        pattern_flags = "--upstream-pattern-assembly=${up_pat} --downstream-pattern-assembly=${down_pat}"
    }


    """
    mkdir -p ${outdir}
    omicsbox trinity \\
        --i-fastq-files-assembly=${reads_list} \\
        ${input_flag} \\
        ${pattern_flags} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
