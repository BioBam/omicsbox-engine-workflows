// --- FILE: modules/cdhit.nf ---
// Wraps: omicsbox cdhit  |  backend: WJOB_ASYNC
// Clusters Trinity transcripts at sequence-identity threshold.
nextflow.enable.dsl=2

process CDHIT {

    input:
    path assembly   // Trinity.fasta from TRINITY

    output:
    path "${task.ext.outdir}/output.fasta", emit: clustered_fasta
    path "${task.ext.outdir}/output-clusters.txt", emit: clusters_file
    path "${task.ext.outdir}/cdhit_report.box", emit: report
    path "${task.ext.outdir}/cdhit_chart.box", emit: chart

    script:
    def outdir     = task.ext.outdir ?: task.process.toLowerCase()
    def args       = task.ext.args   ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox cdhit \\
        --i-input=\$PWD/${assembly} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
