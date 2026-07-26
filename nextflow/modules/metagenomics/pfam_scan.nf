// --- FILE: modules/metagenomics/pfam_scan.nf ---
// Wraps: omicsbox pfam-scan
// Annotates predicted proteins with Pfam protein domains.

process PFAM_SCAN {

    input:
    path fasta   // Predicted protein FASTA

    output:
    path "${task.ext.outdir}/*Report*.box", emit: report          // Pfam-Scan report
    path "${task.ext.outdir}/*Annotations*.box", emit: pfam_output  // Pfam domain annotation project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''


    """
    mkdir -p ${outdir}
    omicsbox pfam-scan \\
        --i-sequences=\$PWD/${fasta} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
