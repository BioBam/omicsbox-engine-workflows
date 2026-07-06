// --- FILE: modules/metagenomics/pfam_scan.nf ---
// Wraps: omicsbox pfam-scan  |  backend: WJOB_ASYNC
// Annotates predicted proteins with Pfam protein domains.
nextflow.enable.dsl=2

process PFAM_SCAN {

    input:
    path proteins   // Predicted protein FASTA (from Prodigal)

    output:
    path "${task.ext.outdir}/*report*.box", emit: report   // Pfam-Scan report
    path "${task.ext.outdir}/*.box", emit: pfam_output      // Pfam domain annotation project

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox pfam-scan \\
        --i-input-sequences=\$PWD/${proteins} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
