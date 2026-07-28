// --- FILE: modules/transcriptomics/rsem.nf ---
// Wraps: omicsbox rsem
// Quantifies transcript- and gene-level expression from RNA-Seq reads against an assembled transcriptome.

process RSEM {

    input:
    path reads             // Input FASTQ reads (single-end or paired-end)
    path assembly          // Reference transcriptome assembly FASTA
    path gene_trans_map    // Optional: gene-to-transcript map

    output:
    path "${task.ext.outdir}/*isoforms*.box", emit: count_table_transcripts  // Isoform (transcript-level) quantification
    // Gene-level quantification. Required in gene-level mode - the workflow feeds this table to its
    // statistics steps there, so an unmatched glob must fail loudly instead of emitting nothing and
    // silently skipping them.
    path "${task.ext.outdir}/*genes*.box", emit: count_table_genes, optional: !(params.rsem?.gene_level)
    path "${task.ext.outdir}/*report*.box", emit: report                     // RSEM report
    path "${task.ext.outdir}/*.bam", emit: bam, optional: true               // Per-sample BAM, reads aligned to transcripts (only if --bam-output=true)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // 'reads' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"
    def input_flag = is_single_end
        ? "--i-fastq-files-single-end=${reads_list}"
        : "--i-fastq-files-paired-end=${reads_list}"

    // Only paired-end needs these: they tell OmicsBox how to pair up R1/R2 files by name
    // (e.g. '_1'/'_2') when multiple sample pairs are collected into the same run.
    def up_pat   = params.getOrDefault('upstream_pattern', '_1')
    def down_pat = params.getOrDefault('downstream_pattern', '_2')
    def pattern_flags = (!is_single_end && up_pat && down_pat)
        ? "--upstream-pattern-counts=${up_pat} --downstream-pattern-counts=${down_pat}"
        : ""

    // --gene-level=true is what enables --i-transcript-to-gene-file
    def gene_level = params.rsem?.gene_level ?: false

    // Optional-input convention: an unwired gene-to-transcript map arrives as channel.value([])
    // (empty List) instead of a real path - that's the "not provided" case to skip.
    def has_map = !(gene_trans_map instanceof List) || !gene_trans_map.isEmpty()
    def genes_trans_map_flag = (gene_level && has_map)
        ? "--i-transcript-to-gene-file=\$PWD/${gene_trans_map}"
        : ""


    """
    mkdir -p ${outdir}
    omicsbox rsem \\
        --i-fasta-file=\$PWD/${assembly} \\
        --gene-level=${gene_level} \\
        ${genes_trans_map_flag} \\
        ${input_flag} \\
        ${pattern_flags} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
