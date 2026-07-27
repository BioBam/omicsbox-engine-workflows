// --- FILE: modules/genome_analysis/augustus.nf ---
// Wraps: omicsbox genefinding-eukaryotic
// Eukaryotic gene finding using AUGUSTUS with evidence-based prediction.

process AUGUSTUS {

    input:
    path fasta                      // Genome FASTA file (soft-masked recommended)
    path hint_est   // Optional: EST/cDNA hint files
    path hint_protein  // Optional: Protein hint files
    path hint_isoseq   // Optional: IsoSeq hint files
    path hint_rna_se   // Optional: RNA-Seq single-end hint files
    path hint_rna_ds   // Optional: RNA-Seq paired-end hint files

    output:
    path "${task.ext.outdir}/*protein*egf*.box", emit: protein_project            // Predicted proteins project
    path "${task.ext.outdir}/*cds*egf*.box", emit: cds_project                    // Predicted CDS project
    path "${task.ext.outdir}/*gff*egf*.box", emit: gff_genes                      // Predicted genes (GFF exported as .box)
    path "${task.ext.outdir}/*report*.box", emit: report                          // Augustus report
    path "${task.ext.outdir}/*distribution*.${params.chart_format}", emit: chart  // CDS-length distribution chart

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    def mode = params.augustus.gene_finding_mode ?: 'abinitio'
    def mode_flag = "--gene-finding-mode=${mode}"

    // Optional-input convention: unwired hint channels arrive as an empty List
    // (channel.value([])) rather than a real path - that's the "not provided" case to skip.
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
