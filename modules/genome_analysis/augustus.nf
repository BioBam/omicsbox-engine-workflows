// --- FILE: modules/augustus.nf ---
// Wraps: omicsbox genefinding-eukaryotic  |  backend: LEGACY_SYNC
// Eukaryotic gene finding using AUGUSTUS with evidence-based prediction.
nextflow.enable.dsl=2

process AUGUSTUS {

    input:
    path fasta                      // Soft-masked genome FASTA file
    path hint_est, optional: true   // Optional: EST/cDNA hint files (evidence for gene prediction)
    path hint_protein, optional: true  // Optional: Protein hint files (evidence for gene prediction)
    path hint_isoseq, optional: true   // Optional: IsoSeq hint files (evidence)
    path hint_rna_se, optional: true   // Optional: RNA-Seq single-end hint files
    path hint_rna_ds, optional: true   // Optional: RNA-Seq paired-end hint files

    output:
    path "${task.ext.outdir}/*.gff", emit: gff_genes                 // Predicted genes in GFF format
    path "${task.ext.outdir}/*cds*project*", emit: cds_project               // OmicsBox CDS project with predictions
    path "${task.ext.outdir}/*protein*project*", emit: protein_project         // OmicsBox protein project with predictions
    path "${task.ext.outdir}/*report*.box", emit: report             // OmicsBox report
    path "${task.ext.outdir}/*chart*.${params.chart_format}", emit: chart               // OmicsBox chart
    
    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // =====================================================================
    // DYNAMIC: Read gene finding mode
    // =====================================================================
    def mode = params.augustus.gene_finding_mode ?: 'abinitio'
    def mode_flag = "--gene-finding-mode=${mode}"

    // =====================================================================
    // DYNAMIC: Optional evidence hints
    // =====================================================================
    def has_est = hint_est ? hint_est.toString() != '[]' : false
    def has_protein = hint_protein ? hint_protein.toString() != '[]' : false
    def has_isoseq = hint_isoseq ? hint_isoseq.toString() != '[]' : false
    def has_rna_se = hint_rna_se ? hint_rna_se.toString() != '[]' : false
    def has_rna_ds = hint_rna_ds ? hint_rna_ds.toString() != '[]' : false

    def est_flag = has_est
        ? "--i-hint-files-est=${hint_est instanceof List ? hint_est.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${hint_est}"}"
        : ""
    def protein_flag = has_protein
        ? "--i-hint-files-protein=${hint_protein instanceof List ? hint_protein.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${hint_protein}"}"
        : ""
    def isoseq_flag = has_isoseq
        ? "--i-hint-files-isoseq=${hint_isoseq instanceof List ? hint_isoseq.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${hint_isoseq}"}"
        : ""
    def rna_se_flag = has_rna_se
        ? "--i-hint-files-rna-seq-u=${hint_rna_se instanceof List ? hint_rna_se.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${hint_rna_se}"}"
        : ""
    def rna_ds_flag = has_rna_ds
        ? "--i-hint-files-rna-seq-d=${hint_rna_ds instanceof List ? hint_rna_ds.collect { file -> "\$PWD/${file}" }.join(',') : "\$PWD/${hint_rna_ds}"}"
        : ""

    // LEGACY_SYNC

    """
    mkdir -p ${outdir}
    omicsbox genefinding-eukaryotic \\
        --i-input-sequences=\$PWD/${fasta} \\
        ${mode_flag} \\
        ${est_flag} \\
        ${protein_flag} \\
        ${isoseq_flag} \\
        ${rna_se_flag} \\
        ${rna_ds_flag} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
