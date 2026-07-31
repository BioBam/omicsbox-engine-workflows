# --- FILE: modules/general_tools/fastqc.smk ---
# Wraps: omicsbox fastqc - quality control assessment of sequence reads.
#
# Generic, reusable rule (operation = `fastqc`). Self-contained: `input.reads`
# accepts EITHER a literal list of FASTQ files OR a directory (e.g. an upstream `directory()`
# output) - the shell tells them apart and comma-joins
# for OmicsBox, the same way trimmomatic.smk builds its own read list. Optional
# adapter/contaminant files follow the trimmomatic.smk `[ -n ... ]` pattern.
# Instantiate with:
#
#   use rule fastqc as <step> with:
#       input:
#           reads=<one or many FASTQ, or an upstream directory(...) output>,
#           adapters=<adapter FASTA or []>,       # [] = no custom adapter list
#           contaminants=<contaminant FASTA or []>,  # [] = no custom contaminant list
#       output:
#           report=os.path.join(stage("<step>"), "fastqc_report.box"),
#           quality=os.path.join(stage("<step>"), "quality_assessment.box"),
#       params:
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# The two names above are STABLE names chosen here, not what the tool writes: both
# boxes come out with a per-run suffix appended before the extension
# (`fastqc_report_<id>_<date>_<6 random chars>.box`), whose last characters are random
# and therefore impossible to predict. The rule resolves each by glob and renames it,
# so downstream steps and `rule all` can refer to a fixed path.


rule fastqc:
    shell:
        r"""
        (
            # input.reads is either a directory (glob its root for FASTQ files,
            # non-recursive - matches trimmomatic.smk's paired-reads-at-root layout)
            # or a Snakemake space-separated file list; OmicsBox wants commas.
            if [ -d "{input.reads}" ]; then
                reads=$(find "{input.reads}" -maxdepth 1 -type f \( -name '*.fastq' -o -name '*.fastq.gz' -o -name '*.fq' -o -name '*.fq.gz' \) | sort | tr '\n' ',' | sed 's/,$//')
            else
                reads=$(echo {input.reads} | tr ' ' ',')
            fi

            adapter_flag=""
            [ -n "{input.adapters}" ] && adapter_flag="--provide-adapters=true --i-adapters={input.adapters}"

            contaminants_flag=""
            [ -n "{input.contaminants}" ] && contaminants_flag="--provide-contaminants=true --i-contaminants={input.contaminants}"

            mkdir -p "{params.outdir}"
            omicsbox fastqc \
                --i-fastq-files="$reads" \
                $adapter_flag \
                $contaminants_flag \
                --local-folder="{params.outdir}" \
                {params.args}

            # Both boxes carry a per-run suffix (name_<id>_<date>_<6 random chars>.box) that
            # cannot be predicted, so resolve each by glob and rename to the stable name the
            # workflow declared.
            mv "$(find "{params.outdir}" -maxdepth 1 -name 'fastqc_report_*.box' | head -n1)" "{output.report}"
            mv "$(find "{params.outdir}" -maxdepth 1 -name 'quality_assessment_*.box' | head -n1)" "{output.quality}"
        ) >{log} 2>&1
        """
