// --- FILE: modules/general_tools/fastqc.nf ---
// Wraps: omicsbox fastqc
// Quality control assessment of sequence reads.

process FASTQC {

    input:
    path reads                  // Input FASTQ reads (single file or list)
    path adapters               // Optional: custom adapter FASTA file
    path contaminants           // Optional: custom contaminant FASTA file

    output:
    path "${task.ext.outdir}/*.box", emit: fastqc_output  // QC report and charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // OmicsBox's PicoCLI parser accepts space- or comma-separated file lists; comma-joining here
    // bundles them into one argument so the greedy parser can't swallow the next flag.
    def fastq_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = "--i-fastq-files=${fastq_list}"

    // Optional-input convention: an empty List (channel.value([])) means the workflow left this
    // input unwired - skip the flag pair in that case; a real path means it was provided.
    def adapters_flag = (!(adapters instanceof List) || !adapters.isEmpty())
        ? "--provide-adapters=true --i-adapters=\$PWD/${adapters}"
        : ""

    def contaminants_flag = (contaminants instanceof List && !contaminants.isEmpty())
        ? "--provide-contaminants=true --i-contaminants=\$PWD/${contaminants}"
        : ""


    """
    mkdir -p ${outdir}
    omicsbox fastqc \\
        ${input_flag} \\
        ${adapters_flag} \\
        ${contaminants_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
