// --- FILE: modules/metagenomics/eggnog_mapper.nf ---
// Wraps: omicsbox eggnog-mapper
// Functional annotation via EggNOG ortholog mapping.

process EGGNOG_MAPPER {

    input:
    path fasta_file     // Input FASTA file (protein or nucleotide sequences)

    output:
    path "${task.ext.outdir}/output_eggnog_*.box", emit: eggnog_project           // EggNOG-annotated OmicsBox project
    path "${task.ext.outdir}/eggnog_mapper_report_*.box", emit: eggnog_report     // EggNOG analysis report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''


    """
    mkdir -p ${outdir}
    omicsbox eggnog-mapper \\
        --i-sequences=\$PWD/${fasta_file} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
