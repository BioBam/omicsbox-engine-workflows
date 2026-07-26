// --- FILE: modules/transcriptomics/sqanti3.nf ---
// Wraps: omicsbox sqanti3
// Classifies and curates long-read transcript isoforms against a reference genome and annotation.

process SQANTI3 {

    input:
    path sqanti_input   // Isoform data: GFF, transcript FASTA/FASTQ, or PacBio reads (mode set by params.sqanti3.pb_or_gff)
    path ref_genome     // Reference genome FASTA
    path ref_annot      // Reference annotation GTF
    path short_reads    // Optional: short-read FASTQ file(s) to validate splice junctions
    path tss_file       // Optional: transcription start site (TSS) annotation BED
    path polya_file     // Optional: polyA motif file
    path polya_peak     // Optional: polyA peak BED
    path fl_counts      // Optional: full-length read counts file
    path rules_json     // Optional: custom filtering rules JSON

    output:
    path "${task.ext.outdir}/*[Rr]esults*.box", emit: results                                  // SQANTI3 results object
    path "${task.ext.outdir}/*[Rr]eport*.box", emit: report                                     // SQANTI3 report
    path "${task.ext.outdir}/*_transcriptome*.gtf", emit: transcriptome_gtf                      // Curated transcriptome GTF (rescued variant when --do-rescue=true)
    path "${task.ext.outdir}/*_isoforms.fasta", emit: isoforms_fasta                             // Curated isoform sequences FASTA
    path "${task.ext.outdir}/*_isoforms_aminoacids.faa", emit: isoforms_amino, optional: true    // Predicted isoform amino-acid sequences (only if --fasta-amino-file=true)
    path "${task.ext.outdir}/*_junctions.txt*", emit: junctions                                  // Splice-junction table (compressed + plain)
    path "${task.ext.outdir}/*_collapsed.group.txt", emit: collapsed_group, optional: true       // Collapsed-isoform grouping (PACBIO mode only)
    path "${task.ext.outdir}/final_classification.txt*", emit: final_classification              // Isoform classification table (compressed + plain)

    script:
    def outdir = task.ext.outdir ?: task.process.toLowerCase()
    def args = task.ext.args ?: ''

    // Input MODE is the single source of truth: --pb-or-gff and its matching --i-*-file are both derived here,
    // so they can never disagree. The mode selects which flag receives the (already validated) input file.
    def mode = params.sqanti3.pb_or_gff
    def input_flag
    if (mode == 'GFF') {
        input_flag = "--i-gff-file=\$PWD/${sqanti_input}"
    } else if (mode == 'TRANSCRIPT') {
        input_flag = "--i-transcriptome-file=\$PWD/${sqanti_input}"
    } else if (mode == 'PACBIO') {
        input_flag = "--i-pac-bio-file=\$PWD/${sqanti_input}"
    } else {
        error "Invalid params.sqanti3.pb_or_gff='${mode}'. Allowed values: GFF, TRANSCRIPT, PACBIO."
    }

    // Optional SHORT-READ support (highly recommended): short reads validate splice junctions during filtering.
    // Presence of the file(s) is the single source of truth (kept coherent, like the input mode):
    //   provided -> --use-of-sr=true --sequencing=<type> --i-short-reads=<files>   (type from params.sqanti3.short_reads_type)
    //   absent   -> --use-of-sr=false
    // WARNING (single-end): with --sequencing=fastq_se SQANTI3 runs STAR only to get splice-junction COVERAGE;
    //                       isoform EXPRESSION is NOT retrieved. Paired-end (fastq_pe) is needed to study expression.
    def sr_flag
    if (!(short_reads instanceof List) || !short_reads.isEmpty()) {
        def sr_list = short_reads instanceof List
            ? short_reads.collect { file -> "\$PWD/${file}" }.join(',')
            : "\$PWD/${short_reads}"
        // short_reads_type has NO default: the workflow already validated it is 'fastq_pe' or 'fastq_se' here.
        def sr_type = params.sqanti3.short_reads_type
        sr_flag = "--use-of-sr=true --sequencing=${sr_type} --i-short-reads=${sr_list}"
        // R1/R2 filename patterns apply ONLY to paired-end short reads. Params are commented by default in the
        // config, so getOrDefault falls back to the tool defaults (_1 / _2) without triggering undefined-param warnings.
        if (sr_type == 'fastq_pe') {
            def up_pat   = params.sqanti3.getOrDefault('upstream_pattern', '_1')
            def down_pat = params.sqanti3.getOrDefault('downstream_pattern', '_2')
            sr_flag += " --upstream-pattern=${up_pat} --downstream-pattern=${down_pat}"
        }
    } else {
        sr_flag = "--use-of-sr=false"
    }

    // Optional EXTRA annotation inputs. Each keeps its --*-check toggle COHERENT with the file presence
    // (present -> check=true + file flag; absent -> check=false), so the toggle and the file never disagree.
    def tss_flag = (!(tss_file instanceof List) || !tss_file.isEmpty())
        ? "--tss-check=true --i-tss-file=\$PWD/${tss_file}"
        : "--tss-check=false"
    def polya_flag = (!(polya_file instanceof List) || !polya_file.isEmpty())
        ? "--polya-check=true --i-polya-file=\$PWD/${polya_file}"
        : "--polya-check=false"
    def polyapeak_flag = (!(polya_peak instanceof List) || !polya_peak.isEmpty())
        ? "--poly-apeak-check=true --i-poly-apeak=\$PWD/${polya_peak}"
        : "--poly-apeak-check=false"
    def fl_flag = (!(fl_counts instanceof List) || !fl_counts.isEmpty())
        ? "--fl-check=true --i-fl-file=\$PWD/${fl_counts}"
        : "--fl-check=false"
    // Custom-rules JSON: no check toggle. Inject --i-json only when provided (required only if --filtering=RULES_FILTER).
    def json_flag = (!(rules_json instanceof List) || !rules_json.isEmpty())
        ? "--i-json=\$PWD/${rules_json}"
        : ""

    """
    mkdir -p ${outdir}
    omicsbox sqanti3 \\
        --pb-or-gff=${mode} \\
        ${input_flag} \\
        --i-ref-genome=\$PWD/${ref_genome} \\
        --i-ref-annot=\$PWD/${ref_annot} \\
        ${sr_flag} \\
        ${tss_flag} \\
        ${polya_flag} \\
        ${polyapeak_flag} \\
        ${fl_flag} \\
        ${json_flag} \\
        --local-folder=\$PWD/${outdir} \\
        ${args}
    """
}
