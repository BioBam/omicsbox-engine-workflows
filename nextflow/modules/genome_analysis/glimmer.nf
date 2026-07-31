// --- FILE: modules/genome_analysis/glimmer.nf ---
// Wraps: omicsbox glimmerv2
// Prokaryotic gene finding using Glimmer with ICM model (creates new model if not provided).

process GLIMMER {

    input:
    path fasta              // Assembled genome FASTA file
    path icm_model   // Optional: pre-built Interpolated Context Model (ICM) file

    output:
    path "${task.ext.outdir}/project.box", emit: project                     // Glimmer sequence project
    path "${task.ext.outdir}/*gff*.box", emit: gff_genes                     // Predicted genes (GFF exported as .box)
    path "${task.ext.outdir}/*.icm", emit: icm_model, optional: true         // Interpolated context model (only when a new model is created)
    path "${task.ext.outdir}/*report*.box", emit: report                     // Glimmer report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // Optional-input convention: no ICM file wired in arrives as an empty List
    // (channel.value([])) - Glimmer then builds a new model instead of reusing one.
    def has_icm = icm_model ? icm_model.toString() != '[]' : false
    def use_icm_flag = has_icm ? "--use-icm=existing" : "--use-icm=create"
    def icm_file_flag = has_icm ? "--i-existing-icmodel=\$PWD/${icm_model}" : ""


    """
    mkdir -p ${outdir}
    omicsbox glimmerv2 \\
        --i-fastafile2=\$PWD/${fasta} \\
        ${use_icm_flag} \\
        ${icm_file_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
