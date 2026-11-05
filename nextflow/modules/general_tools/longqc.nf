// --- FILE: modules/general_tools/longqc.nf ---
// Wraps: omicsbox longqc
// Quality control and trimming for long-read sequencing data.

process LONGQC {

    input:
    path reads                      // Long reads (List of FASTQ/FASTA files)

    output:
    path "${task.ext.outdir}/*results*.box", emit: results            // LongQC results object (QC + read stats)
    path "${task.ext.outdir}/*report*.box", emit: report              // OmicsBox QC report
    path "${task.ext.outdir}/*trimmed*", emit: trimmed_reads, optional: true  // Trimmed/filtered long reads (only if --output-trimmed=true produces them)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"


    """
    mkdir -p ${outdir}
    omicsbox longqc \\
        --i-reads=${reads_list} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}

    # Async tools write each folder output into ${outdir}/<output-key>/; the output globs
    # above expect those files at the top of ${outdir}.
    find ${outdir} -mindepth 2 -maxdepth 2 -type f -exec mv -n {} ${outdir}/ \\;
    find ${outdir} -mindepth 1 -type d -empty -delete
    """
}
