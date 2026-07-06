// --- FILE: modules/transdecoder.nf ---
// Wraps: omicsbox transdecoder  |  backend: WJOB_ASYNC
// Predicts protein-coding regions (ORFs) from assembled transcripts.
nextflow.enable.dsl=2

process TRANSDECODER {

    input:
    path input_fasta        // Transcript FASTA (from TRINITY or CDHIT)
    path gene_trans_map     // Gene-to-transcript mapping file

    output:
    path "${task.ext.outdir}/protein-output.fasta", emit: predicted_proteins
    path "${task.ext.outdir}/cds-output.fasta", emit: predicted_cds
    path "${task.ext.outdir}/output-gff.gff", emit: gff_annotation
    path "${task.ext.outdir}/transdecoder_report.box", emit: report
    path "${task.ext.outdir}/transdecoder_chart.box", emit: chart

    script:
    def outdir     = task.ext.outdir ?: task.process.toLowerCase()
    def args       = task.ext.args   ?: ''

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox transdecoder \\
        --i-input=\$PWD/${input_fasta} \\
        --i-gene-trans-map=\$PWD/${gene_trans_map} \\
        --provide-gene-trans-map=true \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
