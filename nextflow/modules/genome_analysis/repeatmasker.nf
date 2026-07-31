// --- FILE: modules/genome_analysis/repeatmasker.nf ---
// Wraps: omicsbox repeatmasker
// Repeat masking for eukaryotic genome sequences.

process REPEATMASKER {

    input:
    path fasta              // Assembled genome FASTA file
    path database           // Optional: repeat database file

    output:
    path "${task.ext.outdir}/output-repeat-masker.fasta", emit: masked_fasta                             // Soft-masked genome FASTA
    path "${task.ext.outdir}/*gff*.box", emit: gff_repeats                                               // Repeat annotations (GFF exported as .box)
    path "${task.ext.outdir}/*report*.box", emit: report                                                 // RepeatMasker report
    path "${task.ext.outdir}/repeat-type-distribution.${params.chart_format}", emit: distribution        // Repeat-type distribution chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    def engine = params.repeatmasker.search_engine ?: 'rmblast'
    def db_type = params.repeatmasker.database_type ?: 'repbase'
    def engine_flag = "--search-engine=${engine}"

    // The database-type flag only applies to the RMBlast search engine
    def db_type_flag = (engine == 'rmblast') ? "--database-type=${db_type}" : ""

    // Optional-input convention: an unset database file arrives as an empty
    // List (channel.value([])) rather than a real path - that's the "not provided" case to skip.
    def has_db = database ? database.toString() != '[]' : false
    def db_file_flag = has_db ? "--i-database-file=\$PWD/${database}" : ""


    """
    mkdir -p ${outdir}
    omicsbox repeatmasker \\
        --i-fasta-file-repeats=\$PWD/${fasta} \\
        ${engine_flag} \\
        ${db_type_flag} \\
        ${db_file_flag} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
