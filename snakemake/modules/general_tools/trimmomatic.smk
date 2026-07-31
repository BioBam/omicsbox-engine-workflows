# --- FILE: modules/general_tools/trimmomatic.smk ---
# Wraps: omicsbox trimmomatic - adapter/quality trimming of FASTQ reads.
#
# Generic, reusable rule (operation = `trimmomatic`). Self-contained: the
# single/paired handling, the optional adapter and the isolation of unpaired
# reads all live in the shell; the workflow only supplies raw values.
# Instantiate with:
#
#   use rule trimmomatic as <step> with:
#       input:
#           reads=<one or many FASTQ>,
#           adapters=<adapter FASTA or []>,     # [] = no adapter (optional)
#       output:
#           trimmed=directory(stage("<step>")), # whole folder; paired reads at its root
#       params:
#           single_end="true" if config["input_single_end"] else "false",
#           up_pattern=config.get("upstream_pattern", "_1"),
#           down_pattern=config.get("downstream_pattern", "_2"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# Output layout:
#   <step>/*.fastq*            -> trimmed PAIRED reads (consumers glob the root)
#   <step>/unpaired/*.fastq*   -> unpaired reads, created ONLY in paired-end runs
#                                 (single-end never creates this folder)
#   <step>/*report*.box        -> trimming report
#
# Downstream consumers take the folder and glob its ROOT (non-recursive) to get
# only the paired reads; the unpaired ones live one level down and are not picked
# up. OmicsBox writes both sets into --local-folder, so the rule moves the unpaired
# ones into the sub-folder itself.


rule trimmomatic:
    shell:
        r"""
        (
            mkdir -p {output.trimmed}

            # Snakemake space-separates multiple input files; OmicsBox wants them comma-separated.
            reads=$(echo {input.reads} | tr ' ' ',')

            # Single-end vs paired-end input flag (+ read-pair patterns for PE).
            if [ "{params.single_end}" = "true" ]; then
                input_flag="--i-input-sequencing-data-furi-single-end=$reads"
                pattern_flags=""
            else
                input_flag="--i-input-sequencing-data-furi-paired-end=$reads"
                pattern_flags="--upstream-pattern-preprocessing={params.up_pattern} --downstream-pattern-preprocessing={params.down_pattern}"
            fi

            # Optional adapter file: added only if one was provided ([] renders empty).
            adapter_flag=""
            [ -n "{input.adapters}" ] && adapter_flag="--i-adapter-file={input.adapters}"

            omicsbox trimmomatic \
                $input_flag \
                $pattern_flags \
                $adapter_flag \
                --local-folder="{output.trimmed}" \
                {params.args}

            # Isolate unpaired reads into a subfolder ONLY if they exist (paired-end).
            # Single-end produces none, so no (misleading) empty 'unpaired/' folder is created.
            if ls {output.trimmed}/unpaired_*.fastq* >/dev/null 2>&1; then
                mkdir -p {output.trimmed}/unpaired
                mv {output.trimmed}/unpaired_*.fastq* {output.trimmed}/unpaired/
            fi
        ) >{log} 2>&1
        """
