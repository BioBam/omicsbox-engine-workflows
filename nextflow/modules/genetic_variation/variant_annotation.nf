// --- FILE: modules/genetic_variation/variant_annotation.nf ---
// Wraps: omicsbox variant-annotation
// Variant Annotation: annotates VCF variants with functional effects using a genome + GTF annotation.

process VARIANT_ANNOTATION {

    input:
    path vcf          // VCF with variants to annotate
    path annotation   // Annotation GTF matching the genome species/version
    path genome       // Genome FASTA (must match the genome used for variant calling)

    output:
    path "${task.ext.outdir}/*[Tt]able*.box", emit: annotation_table   // Variant annotation table
    path "${task.ext.outdir}/*[Rr]eport*.box", emit: report            // Variant annotation report
    path "${task.ext.outdir}/*[Tt]ypes*.box", emit: types_chart        // Pie chart of annotated variant types

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    """
    mkdir -p ${outdir}
    omicsbox variant-annotation \\
        --i-vcf-file=\$PWD/${vcf} \\
        --i-annotation=\$PWD/${annotation} \\
        --i-genome=\$PWD/${genome} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
