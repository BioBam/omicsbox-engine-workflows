// --- FILE: modules/genome_analysis/abyss.nf ---
// Wraps: omicsbox abyss
// DNA-Seq de novo genome assembly for eukaryotic genomes using ABySS assembler.

process ABYSS {

    input:
    path reads                 // Trimmed FASTQ reads (single-end or paired-end)
    path opt_linked_reads    // Optional: Linked reads for hybrid assembly
    path opt_add_paired_end  // Optional: Additional paired-end reads
    path opt_mate_pair       // Optional: Mate-pair reads for scaffolding
    path opt_long_seqs       // Optional: Long sequence reads

    output:
    path "${task.ext.outdir}/scaffolds-file.fasta", emit: scaffolds          // Scaffolds FASTA
    path "${task.ext.outdir}/contigs-file.fasta", emit: contigs              // Contigs FASTA
    path "${task.ext.outdir}/unitigs-file.fasta", emit: unitigs              // Unitigs FASTA
    path "${task.ext.outdir}/long-scaffolds-file.fasta", emit: long_scaffolds, optional: true  // Long scaffolds FASTA (only if long sequence libraries are provided)
    path "${task.ext.outdir}/assembly-scaffolds.dot", emit: scaffolds_graph, optional: true  // Scaffold assembly graph (only if --save-graph=true)
    path "${task.ext.outdir}/assembly-contigs.dot", emit: contigs_graph, optional: true      // Contig assembly graph (only if --save-graph=true)
    path "${task.ext.outdir}/*report*.box", emit: report                     // ABySS report
    path "${task.ext.outdir}/*chart*.${params.chart_format}", emit: chart    // ABySS chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // Single-End vs Paired-End input flag
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"
    def input_flag = is_single_end
        ? "--i-input-sequencing-data-abyss-single-end=${reads_list}"
        : "--i-input-sequencing-data-abyss-paired-end=${reads_list}"

    // Paired-end pattern flags
    def pattern_flags = ""
    if (!is_single_end) {
        def up_pat = params.getOrDefault('upstream_pattern', '_1')
        def down_pat = params.getOrDefault('downstream_pattern', '_2')
        pattern_flags = "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
    }

    // Optional-input convention: unwired optional channels arrive as an empty
    // List (channel.value([])); providing any of them enables --use-additional-data=true.
    def has_linked = opt_linked_reads ? opt_linked_reads.toString() != '[]' : false
    def has_add_pe = opt_add_paired_end ? opt_add_paired_end.toString() != '[]' : false
    def has_mp = opt_mate_pair ? opt_mate_pair.toString() != '[]' : false
    def has_long = opt_long_seqs ? opt_long_seqs.toString() != '[]' : false
    def has_any_opt = has_linked || has_add_pe || has_mp || has_long
    def use_opt_flag = has_any_opt ? "--use-additional-data=true" : ""

    def linked_flag = has_linked
        ? "--i-optional-data-abyss-linked-reads=${opt_linked_reads instanceof List ? opt_linked_reads.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${opt_linked_reads}"}"
        : ""
    def add_pe_flag = has_add_pe
        ? "--i-optional-data-abyss-add-paired-end=${opt_add_paired_end instanceof List ? opt_add_paired_end.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${opt_add_paired_end}"}"
        : ""
    def mp_flag = has_mp
        ? "--i-optional-data-abyss-mate-pair=${opt_mate_pair instanceof List ? opt_mate_pair.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${opt_mate_pair}"}"
        : ""
    def long_flag = has_long
        ? "--i-optional-data-abyss-long-sequences=${opt_long_seqs instanceof List ? opt_long_seqs.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${opt_long_seqs}"}"
        : ""


    """
    mkdir -p ${outdir}
    omicsbox abyss \\
        ${input_flag} \\
        ${pattern_flags} \\
        ${use_opt_flag} \\
        ${linked_flag} \\
        ${add_pe_flag} \\
        ${mp_flag} \\
        ${long_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
