// --- FILE: modules/transcriptomics/flair.nf ---
// Wraps: omicsbox flair
// Reconstructs and quantifies transcript isoforms from long reads.

process FLAIR {

    input:
    path reads          // Raw long reads FASTA/Q (one or more files)
    path ref_genome     // Reference genome FASTA
    path annotation     // Optional: reference transcriptome annotation GTF
    path aligned_reads  // Optional: aligned reads BAM (e.g. from Minimap2)
    path junction_bed   // Optional: short-read splice junctions (BAM or STAR SJ.out.tab)

    output:
    path "${task.ext.outdir}/*transcriptome*.gtf", emit: isoforms                 // Reconstructed transcriptome GTF (isoforms)
    path "${task.ext.outdir}/*[Cc]ount*.box", emit: count_table                  // Transcript-level count-table project
    path "${task.ext.outdir}/*counts*.tsv", emit: counts                         // Full-length isoform counts (TSV)
    path "${task.ext.outdir}/*[Rr]eport*.box", emit: report                      // FLAIR report
    path "${task.ext.outdir}/*[Ll]ength*.${params.chart_format}", emit: chart    // Isoform length chart
    path "${task.ext.outdir}/*fasta*", emit: fasta, optional: true               // Isoform sequences FASTA

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // 'reads' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    // Optional-input convention: an unwired aligned_reads channel.value([]) means "not provided" -
    // skip the external alignment and let FLAIR align internally, keeping --aligned-reads-check in sync.
    def aligned_flag
    if (!(aligned_reads instanceof List) || !aligned_reads.isEmpty()) {
        def aligned_list = aligned_reads instanceof List
            ? aligned_reads.collect { file -> "\$PWD/${file}" }.join(',')
            : "\$PWD/${aligned_reads}"
        aligned_flag = "--aligned-reads-check=true --i-aligned-reads=${aligned_list}"
    } else {
        aligned_flag = "--aligned-reads-check=false"
    }

    // Optional-input convention: channel.value([]) means no annotation was wired in - keep
    // --use-annotation-file in sync with whether the GTF is actually present.
    def annotation_flag = (!(annotation instanceof List) || !annotation.isEmpty())
        ? "--use-annotation-file=true --i-annotation-file=\$PWD/${annotation}"
        : "--use-annotation-file=false"

    // Optional-input convention: channel.value([]) means no junction file was wired in - omit the flag.
    def junc_bed_flag = (!(junction_bed instanceof List) || !junction_bed.isEmpty())
        ? "--i-junction-bed=${junction_bed instanceof List ? junction_bed.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${junction_bed}"}"
        : ""

    """
    mkdir -p ${outdir}
    omicsbox flair \\
        --i-input-files=${reads_list} \\
        --i-ref-genome=\$PWD/${ref_genome} \\
        ${annotation_flag} \\
        ${aligned_flag} \\
        ${junc_bed_flag} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
