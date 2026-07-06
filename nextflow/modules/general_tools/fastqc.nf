// --- FILE: modules/fastqc.nf ---
// Wraps: omicsbox fastqc  |  backend: WJOB_ASYNC
// Quality control assessment of sequence reads.
nextflow.enable.dsl=2

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

    // ARCHITECTURAL NOTE: OmicsBox's PicoCLI accepts both space-separated (greedy arity)
    // and comma-separated inputs. We enforce comma separation (.join(',')) to bundle all files
    // into a single, unbreakable argument. This prevents PicoCLI's greedy parser from
    // accidentally swallowing adjacent flags.
    def fastq_list = reads instanceof List
        ? reads.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${reads}"

    def input_flag = "--i-fastq-files=${fastq_list}"

    def adapters_flag = (!(adapters instanceof List) || !adapters.isEmpty())
        ? "--provide-adapters=true --i-adapters=\$PWD/${adapters}"
        : ""

    def contaminants_flag = (contaminants instanceof List && !contaminants.isEmpty())
        ? "--provide-contaminants=true --i-contaminants=\$PWD/${contaminants}"
        : ""

    // WJOB_ASYNC
    def cloud_flag = params.cloud_folder ? "--cloud-folder=${params.cloud_folder}" : ""

    """
    mkdir -p ${outdir}
    omicsbox fastqc \\
        ${input_flag} \\
        ${adapters_flag} \\
        ${contaminants_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${cloud_flag} \\
        ${args}
    """
}
