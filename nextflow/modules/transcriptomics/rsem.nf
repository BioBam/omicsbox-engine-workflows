// --- FILE: modules/rsem.nf ---
// Wraps: omicsbox rsem  |  backend: WJOB_ASYNC
// Quantifies read expression against Trinity assembly.
nextflow.enable.dsl=2

process RSEM {

    input:
    path reads
    path assembly           
    path gene_trans_map     

    output:
    path "${task.ext.outdir}/*transcripts*counts*.box", emit: count_table_transcripts
    path "${task.ext.outdir}/*genes*counts*.box", emit: count_table_genes, optional: true
    path "${task.ext.outdir}/*report*.box", emit: report

    script:
    def outdir        = task.ext.outdir ?: task.process.toLowerCase()
    def args          = task.ext.args   ?: ''
    def is_single_end = params.input_single_end ? true : false

    // Single-End vs Paired-End input flag
    def reads_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"
    def input_flag = is_single_end
        ? "--i-input-sequencing-data-furi-single-end=${reads_list}"
        : "--i-input-sequencing-data-furi-paired-end=${reads_list}"

    def up_pat   = params.get('upstream_pattern')
    def down_pat = params.get('downstream_pattern')
    def pattern_flags = (!is_single_end && up_pat && down_pat)
        ? "--upstream-pattern-preprocessing=${up_pat} --downstream-pattern-preprocessing=${down_pat}"
        : ""

    def genes_trans_map_flag = (!(gene_trans_map instanceof List) || !gene_trans_map.isEmpty())
        ? "--i-transcript-to-gene-file=\$PWD/${gene_trans_map}"
        : ""

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox rsem \\
        --i-fasta-file=\$PWD/${assembly} \\
        ${genes_trans_map_flag} \\
        ${input_flag} \\
        ${pattern_flags} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
