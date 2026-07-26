// --- FILE: modules/genome_analysis/spades.nf ---
// Wraps: omicsbox spades
// DNA-Seq de novo genome assembly with comprehensive mate-pair and hybrid assembly support.

process SPADES {

    input:
    path reads                   // FASTQ reads (single-end or paired-end)
    path opt_mp_fr            // Optional: Mate-pair reads (FR orientation)
    path opt_mp_rf            // Optional: Mate-pair reads (RF orientation)
    path opt_mp_ff            // Optional: Mate-pair reads (FF orientation)
    path sanger_reads         // Optional: Sanger sequencing reads
    path pacbio_reads         // Optional: PacBio long reads for hybrid assembly
    path nanopore_reads       // Optional: Nanopore long reads for hybrid assembly
    path trusted_contigs      // Optional: Trusted contigs for hybrid assembly
    path untrusted_contigs    // Optional: Untrusted contigs for hybrid assembly

    output:
    path "${task.ext.outdir}/scaffolds.fasta", emit: scaffolds                                       // Scaffolds FASTA
    path "${task.ext.outdir}/contigs.fasta", emit: contigs                                           // Contigs FASTA
    path "${task.ext.outdir}/*report*.box", emit: report                                             // SPAdes report (spades_report.box)
    path "${task.ext.outdir}/*chart*.${params.chart_format}", emit: chart                            // SPAdes Nx-plot chart (spades_chart.box; extension follows chart_format)
    path "${task.ext.outdir}/assembly_graph_with_scaffolds.gfa", emit: assembly_graph, optional: true                // Assembly graph with scaffolds (only if --save-graph=true)
    path "${task.ext.outdir}/assembly_graph_after_simplification.gfa", emit: assembly_graph_simplified, optional: true  // Simplified assembly graph (only if --save-graph=true)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''
    def is_single_end = params.input_single_end ? true : false

    // paired_end_library_type selects which SPAdes paired-end flag variant to use
    // (e.g. regular paired-end vs mate-pair library)
    def library_type = params.spades.paired_end_library_type
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"
    def input_flag = is_single_end
        ? "--i-input-sequencing-data-spades-single-end=${reads_list}"
        : "--i-input-sequencing-data-spades-${library_type}=${reads_list}"

    // Paired-end pattern flags tell OmicsBox how to pair up R1/R2 files by name
    def pattern_flags = ""
    if (!is_single_end) {
        def up_pat = params.getOrDefault('upstream_pattern', '_1')
        def down_pat = params.getOrDefault('downstream_pattern', '_2')
        pattern_flags = "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
    }

    // Optional-input convention: unwired mate-pair channels arrive as an empty
    // List (channel.value([])); providing any of them enables --use-mp-optional-data=true.
    def has_mp_fr = opt_mp_fr ? opt_mp_fr.toString() != '[]' : false
    def has_mp_rf = opt_mp_rf ? opt_mp_rf.toString() != '[]' : false
    def has_mp_ff = opt_mp_ff ? opt_mp_ff.toString() != '[]' : false
    def has_any_mp = has_mp_fr || has_mp_rf || has_mp_ff
    def use_mp_flag = has_any_mp ? "--use-mp-optional-data=true" : ""

    def mp_fr_flag = has_mp_fr
        ? "--i-mp-optional-data-spades-mate-pair-fr=${opt_mp_fr instanceof List ? opt_mp_fr.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${opt_mp_fr}"}"
        : ""
    def mp_rf_flag = has_mp_rf
        ? "--i-mp-optional-data-spades-mate-pair-rf=${opt_mp_rf instanceof List ? opt_mp_rf.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${opt_mp_rf}"}"
        : ""
    def mp_ff_flag = has_mp_ff
        ? "--i-mp-optional-data-spades-mate-pair-ff=${opt_mp_ff instanceof List ? opt_mp_ff.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${opt_mp_ff}"}"
        : ""

    // Optional-input convention: unwired hybrid-assembly channels arrive as an
    // empty List (channel.value([])); providing any of them enables --use-data-for-hybrid-assembly=true.
    def has_sanger = sanger_reads ? sanger_reads.toString() != '[]' : false
    def has_pacbio = pacbio_reads ? pacbio_reads.toString() != '[]' : false
    def has_nanopore = nanopore_reads ? nanopore_reads.toString() != '[]' : false
    def has_trusted = trusted_contigs ? trusted_contigs.toString() != '[]' : false
    def has_untrusted = untrusted_contigs ? untrusted_contigs.toString() != '[]' : false
    def is_hybrid = has_sanger || has_pacbio || has_nanopore || has_trusted || has_untrusted
    def use_hybrid_flag = is_hybrid ? "--use-data-for-hybrid-assembly=true" : ""

    def sanger_flag = has_sanger
        ? "--i-data-for-hybrid-assembly-spades-sanger=${sanger_reads instanceof List ? sanger_reads.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${sanger_reads}"}"
        : ""
    def pacbio_flag = has_pacbio
        ? "--i-data-for-hybrid-assembly-spades-pacbio=${pacbio_reads instanceof List ? pacbio_reads.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${pacbio_reads}"}"
        : ""
    def nanopore_flag = has_nanopore
        ? "--i-data-for-hybrid-assembly-spades-nanopore=${nanopore_reads instanceof List ? nanopore_reads.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${nanopore_reads}"}"
        : ""
    def trusted_flag = has_trusted
        ? "--i-data-for-hybrid-assembly-spades-trusted-contigs=${trusted_contigs instanceof List ? trusted_contigs.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${trusted_contigs}"}"
        : ""
    def untrusted_flag = has_untrusted
        ? "--i-data-for-hybrid-assembly-spades-untrusted-contigs=${untrusted_contigs instanceof List ? untrusted_contigs.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${untrusted_contigs}"}"
        : ""


    """
    mkdir -p ${outdir}
    omicsbox spades \\
        ${input_flag} \\
        ${pattern_flags} \\
        ${use_mp_flag} \\
        ${mp_fr_flag} \\
        ${mp_rf_flag} \\
        ${mp_ff_flag} \\
        ${use_hybrid_flag} \\
        ${sanger_flag} \\
        ${pacbio_flag} \\
        ${nanopore_flag} \\
        ${trusted_flag} \\
        ${untrusted_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
