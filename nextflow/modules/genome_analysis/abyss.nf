// --- FILE: modules/abyss.nf ---
// Wraps: omicsbox abyss  |  backend: WJOB_ASYNC
// DNA-Seq de novo genome assembly for eukaryotic genomes using ABySS assembler.
nextflow.enable.dsl=2

process ABYSS {

    input:
    path reads                 // Trimmed FASTQ reads (single-end or paired-end)
    path opt_linked_reads, optional: true    // Optional: Linked reads for hybrid assembly
    path opt_add_paired_end, optional: true  // Optional: Additional paired-end reads
    path opt_mate_pair, optional: true       // Optional: Mate-pair reads for scaffolding
    path opt_long_seqs, optional: true       // Optional: Long sequence reads

    output:
    path "${task.ext.outdir}/*unitigs.fa", emit: unitigs              // Assembled unitigs FASTA file
    path "${task.ext.outdir}/*contigs.fa", emit: contigs              // Assembled contigs FASTA file
    path "${task.ext.outdir}/*scaffolds.fa", emit: scaffolds          // Assembled scaffolds FASTA file
    path "${task.ext.outdir}/*long-scaffolds.fa", emit: long_scaffolds  // Assembled long scaffolds FASTA file   
    path "${task.ext.outdir}/*report*.box", emit: report              // OmicsBox report
    path "${task.ext.outdir}/*Nx_plot*", emit: nx_plot                // Nx plot chart
    path "${task.ext.outdir}/*graph", emit: abyss_graph, optional: true  // ABySS graph visualization

    script:
    def outdir        = task.ext.outdir ?: task.process.toLowerCase()
    def args          = task.ext.args   ?: ''
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
        def up_pat = params.keySet().contains('upstream_pattern') && params.upstream_pattern ? params.upstream_pattern : '_1'
        def down_pat = params.keySet().contains('downstream_pattern') && params.downstream_pattern ? params.downstream_pattern : '_2'
        pattern_flags = "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
    }

    // DYNAMIC: Optional additional data (triggers --use-additional-data=true)
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

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

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
        ${cloud_flag} \\
        ${args}
    """
}
