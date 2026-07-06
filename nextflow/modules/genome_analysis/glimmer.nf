// --- FILE: modules/glimmer.nf ---
// Wraps: omicsbox runglimmer  |  backend: LEGACY_SYNC
// Prokaryotic gene finding using Glimmer with ICM model (creates new model if not provided).

nextflow.enable.dsl=2

process GLIMMER {

    tag { fasta.name }

    input:
    path fasta              // Assembled genome FASTA file
    path icm_model, optional: true   // Optional: Interpolated Context Model (ICM) file. If null, creates new model.

    output:
    path "${task.ext.outdir}/*.gff", emit: gff_genes             // Predicted genes in GFF format
    path "${task.ext.outdir}/*project*", emit: project           // OmicsBox sequence project
    path "${task.ext.outdir}/*report*.box", emit: report         // OmicsBox report

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // =====================================================================
    // DYNAMIC ICM MODEL LOGIC (Optional: Create vs Use Existing)
    // =====================================================================
    def has_icm = icm_model ? icm_model.toString() != '[]' : false
    def use_icm_flag = has_icm ? "--use-icm=existing" : "--use-icm=create"
    def icm_file_flag = has_icm ? "--i-existing-icmodel=\$PWD/${icm_model}" : ""

    // LEGACY_SYNC

    """
    mkdir -p ${outdir}
    omicsbox runglimmer \\
        --i-fastafile2=\$PWD/${fasta} \\
        ${use_icm_flag} \\
        ${icm_file_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
