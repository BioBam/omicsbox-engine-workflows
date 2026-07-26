// --- FILE: modules/transcriptomics/htseq.nf ---
// Wraps: omicsbox htseq
// RNA-Seq read quantification at gene level from aligned BAM files and genome annotation.

process HTSEQ {

    input:
    path bam_files            // BAM alignment file(s)
    path gff                  // Genome annotation in GFF/GTF format

    output:
    path "${task.ext.outdir}/count_table.box", emit: count_table   // Gene-level count-table project
    path "${task.ext.outdir}/*report*.box", emit: report           // HTSeq report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // 'bam_files' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def bam_list = bam_files instanceof List
        ? bam_files.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${bam_files}"

    """
    mkdir -p ${outdir}
    omicsbox htseq \\
        --i-alignment-files=${bam_list} \\
        --i-gff-file=\$PWD/${gff} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
