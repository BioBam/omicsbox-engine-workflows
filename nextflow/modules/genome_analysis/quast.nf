// --- FILE: modules/quast.nf ---
// Wraps: omicsbox quast  |  backend: WJOB_ASYNC
// Quality assessment of genome assemblies using QUAST.
nextflow.enable.dsl=2

process QUAST {

    input:
    path assembly              
    path reference             

    output:
    path "${task.ext.outdir}/*", emit: quast_results            // QUAST results 
    path "${task.ext.outdir}/*report*.box", emit: report        // OmicsBox report
    path "${task.ext.outdir}/*chart*", emit: ngx_chart, optional: true  // NGx chart visualization

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox quast \\
        --i-assemblies=${assembly instanceof List ? assembly.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${assembly}"} \\
        --i-reference=\$PWD/${reference} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
