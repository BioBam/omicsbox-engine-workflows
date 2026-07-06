// --- FILE: modules/star.nf ---
// Wraps: omicsbox star-aligner  |  backend: WJOB_ASYNC
// RNA-Seq read alignment to reference genome using STAR aligner.
nextflow.enable.dsl=2

process STAR {

    input:
    path reads                // Trimmed FASTQ reads (single-end or paired-end)
    path fasta                // Reference genome FASTA file
    path annotation           // Genome annotation in GTF/GFF format

    output:
    path "${task.ext.outdir}/*.bam", emit: bam_sorted             // Coordinate-sorted BAM alignment file(s)
    path "${task.ext.outdir}/*.bam.bai", emit: bam_index, optional: true  // BAM index files
    path "${task.ext.outdir}/*SJ.out.tab", emit: splice_junctions, optional: true  // Splice junction coordinates
    path "${task.ext.outdir}/*report*.box", emit: report          // OmicsBox report

    script:
    def outdir        = task.ext.outdir ?: task.process.toLowerCase()
    def args          = task.ext.args   ?: ''
    def is_single_end = params.input_single_end ? true : false

    // Single-End vs Paired-End input flag
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"
    def input_flag = is_single_end
        ? "--i-input-sequencing-data-single-end=${reads_list}"
        : "--i-input-sequencing-data-paired-end=${reads_list}"

    // Paired-end pattern flags — only injected when patterns are configured in params
    def up_pat   = params.get('upstream_pattern')
    def down_pat = params.get('downstream_pattern')
    def pattern_flags = (!is_single_end && up_pat && down_pat)
        ? "--upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
        : ""

    // WJOB_ASYNC: --cloud-folder required for cloud-backed runs
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox star-aligner \\
        ${input_flag} \\
        ${pattern_flags} \\
        --i-fasta-file=\$PWD/${fasta} \\
        --i-annotation-file=\$PWD/${annotation} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
