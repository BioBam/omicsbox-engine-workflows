// --- FILE: modules/repeatmasker.nf ---
// Wraps: omicsbox repeatmasker  |  backend: LEGACY_SYNC
// Repeat masking for eukaryotic genome sequences.

nextflow.enable.dsl=2

process REPEATMASKER {

    input:
    path fasta              // Assembled genome FASTA file
    path database, optional: true           // Repeat database file 

    output:
    path "${task.ext.outdir}/*.masked", emit: masked_fasta          // Masked genome FASTA file
    path "${task.ext.outdir}/*.gff", emit: gff_repeats              // GFF annotation of repeats
    path "${task.ext.outdir}/*tbl.${params.chart_format}", emit: repeat_table              // Tabular summary of repeats
    path "${task.ext.outdir}/*report*.box", emit: report            // OmicsBox report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // =====================================================================
    // DYNAMIC: Read engine and database type choices from params
    // =====================================================================
    def engine = params.repeatmasker.search_engine ?: 'rmblast'
    def db_type = params.repeatmasker.database_type ?: 'repbase'

    def engine_flag = "--search-engine=${engine}"

    // The database-type flag is only valid/relevant for RMBlast engine
    def db_type_flag = (engine == 'rmblast') ? "--database-type=${db_type}" : ""

    // =====================================================================
    // DYNAMIC: File Injection logic (Safe empty list check)
    // Database file only required for RMBlast with RepBase or Custom databases
    // =====================================================================
    def has_db = database ? database.toString() != '[]' : false
    def db_file_flag = has_db ? "--i-database-file=\$PWD/${database}" : ""

    // LEGACY_SYNC

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
