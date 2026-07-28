// --- FILE: modules/genome_analysis/flye.nf ---
// Wraps: omicsbox flye
// Long-read de novo genome assembly using Flye.

process FLYE {

    input:
    path reads                      // Trimmed long reads (List of FASTQ/FASTA files)

    output:
    path "${task.ext.outdir}/assembly-output-file.fasta", emit: assembly   // Assembled contigs FASTA
    path "${task.ext.outdir}/*report*.box", emit: report                   // Flye report
    path "${task.ext.outdir}/*chart*.box", emit: chart  // Flye chart
    path "${task.ext.outdir}/graph-file.gfa", emit: assembly_graph, optional: true  // Assembly graph (only if --save-graph=true)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // Maps the configured library type to its OmicsBox CLI input flag
    def lib_type = params.flye.library_type ?: 'pacbio_raw'
    def lib_flag = [
        'pacbio_raw' : '--i-input-sequencing-data-pacbio-raw',
        'pacbio_corr': '--i-input-sequencing-data-pacbio-corrected',
        'pacbio_hifi': '--i-input-sequencing-data-pacbio-hifi',
        'nano_raw'   : '--i-input-sequencing-data-nanopore-raw',
        'nano_corr'  : '--i-input-sequencing-data-nanopore-corrected'
    ][lib_type]

    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"


    """
    mkdir -p ${outdir}
    omicsbox flye \\
        ${lib_flag}=${reads_list} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
