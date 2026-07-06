// --- FILE: modules/ips.nf ---
// Wraps: omicsbox ips  |  backend: WJOB_ASYNC
// Protein domain and functional annotation via InterProScan.
nextflow.enable.dsl=2

process INTERPROSCAN {

    input:
    path omicsbox_project   // OmicsBox Sequence Project (.box) from LOAD_FASTA

    output:
    path "${task.ext.outdir}/*.box", emit: ips_project                              // InterProScan-annotated OmicsBox project
    path "${task.ext.outdir}/*.{xml,json,gff3,tsv}", emit: export_files, optional: true  // Optional export formats

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox ips \\
        --i-local-project=\$PWD/${omicsbox_project} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
