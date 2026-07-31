# --- FILE: modules/metagenomics/eggnog_mapper.smk ---
# Wraps: omicsbox eggnog-mapper - EggNOG ortholog annotation (consumes raw FASTA).
#
# Generic, reusable rule (operation = `eggnog_mapper`). EggNOG writes two projects
# with run-dependent names; this rule normalises them to the two `output` names
# the workflow declares. Instantiate:
#   use rule eggnog_mapper as <step> with:
#       input:  fasta=<input FASTA>
#       output: annotations=<step>/eggnog_annotations.box, report=<step>/eggnog_report.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")


rule eggnog_mapper:
    shell:
        r"""
        (
            mkdir -p {params.outdir}
            omicsbox eggnog-mapper \
                --i-sequences="{input.fasta}" \
                --local-folder="{params.outdir}" \
                {params.args}
            mv "$(find "{params.outdir}" -maxdepth 1 -name 'output_eggnog_*.box' | head -n1)" "{output.annotations}"
            mv "$(find "{params.outdir}" -maxdepth 1 -name 'eggnog_mapper_report_*.box' | head -n1)" "{output.report}"
        ) >{log} 2>&1
        """
