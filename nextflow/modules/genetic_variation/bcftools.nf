// --- FILE: modules/genetic_variation/bcftools.nf ---
// Wraps: omicsbox variantcalling-multipackage
// Variant Calling with BCFtools: calls SNPs/indels from BAM alignments against a reference genome.

process BCFTOOLS {

    input:
    path bams               // Input BAM alignments (one or more samples)
    path ref_gen            // Reference genome FASTA, faidx-indexed (Ensembl recommended)
    path group_experiment   // Optional: tab-delimited sample-to-group mapping (requires --use-groups=true)

    output:
    path "${task.ext.outdir}/*.vcf{,.gz}", emit: vcf                        // Called variants VCF
    path "${task.ext.outdir}/*[Rr]eport*.box", emit: report                // Variant calling report
    path "${task.ext.outdir}/*{depth,quality}*.${params.chart_format}", emit: charts   // Read-depth and mapping-quality charts

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // 'bams' is a single path for one file, or a List when the workflow .collect()s multiple samples.
    def bams_list = bams instanceof List
        ? bams.collect { file -> "\$PWD/${file}" }.join(',')
        : "\$PWD/${bams}"

    // Optional-input convention: when no grouping file is wired in, the workflow passes an empty
    // List (channel.value([])) instead of a real path - that's the "not provided" case to skip.
    def group_flag = (!(group_experiment instanceof List) || !group_experiment.isEmpty())
        ? "--i-group-experiment=\$PWD/${group_experiment}"
        : ""

    """
    mkdir -p ${outdir}
    omicsbox variantcalling-multipackage \\
        --i-input-files=${bams_list} \\
        --i-ref-gen=\$PWD/${ref_gen} \\
        ${group_flag} \\
        --chart-format=${params.chart_format} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
