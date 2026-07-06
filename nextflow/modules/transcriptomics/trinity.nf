// --- FILE: modules/trinity.nf ---
// Wraps: omicsbox trinity  |  backend: WJOB_ASYNC
// De-novo RNA-Seq assembly. 
nextflow.enable.dsl=2

process TRINITY {

    input:
    path reads

    output:
    path "${task.ext.outdir}/transcripts.fasta", emit: assembly
    path "${task.ext.outdir}/supertranscripts.fasta", emit: supertranscripts, optional: true
    path "${task.ext.outdir}/*map*.txt", emit: gene_trans_map
    path "${task.ext.outdir}/*report*.box", emit: report
    path "${task.ext.outdir}/read_content.box", emit: read_content, optional: true

    script:
    def outdir        = task.ext.outdir ?: task.process.toLowerCase()
    def args          = task.ext.args   ?: ''
    def is_single_end = params.input_single_end ? true : false

    def reads_list = reads instanceof List 
        ? reads.collect { file -> "\$PWD/${file}" }.join(',') 
        : "\$PWD/${reads}"
        
    def input_flag = is_single_end ? "--sequencing=Single" : "--sequencing=Paired"

    def pattern_flags = ""

    // Check if the input is Paired-End 
    if (!is_single_end) {
        def up_pat = params.keySet().contains('upstream_pattern') ? params.upstream_pattern : '_1'
        def down_pat = params.keySet().contains('downstream_pattern') ? params.downstream_pattern : '_2'
        pattern_flags = "--upstream-pattern-assembly=${up_pat} --downstream-pattern-assembly=${down_pat}"
    }

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox trinity \\
        --i-fastq-files-assembly=${reads_list} \\
        ${input_flag} \\
        ${pattern_flags} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
