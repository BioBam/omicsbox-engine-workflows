# --- FILE: modules/transcriptomics/edger.smk ---
# Wraps: omicsbox edger - pairwise differential expression analysis (edgeR) on a
# count table against an experimental design.
#
# Generic, reusable rule (operation = `edger`). Instantiate with:
#
#   use rule edger as <step> with:
#       input:
#           count_table=<count table .box>,
#           design=<experimental design file (tab-delimited)>,
#       output:
#           results=os.path.join(stage("<step>"), "edger_output_project.box"),
#           report=os.path.join(stage("<step>"), "edger_summary_report.box"),
#       params:
#           outdir=stage("<step>"),
#           args=join_args("<step>"),
#       log:
#           logfile("<step>")
#
# The design file is MANDATORY here - it is the statistical model.
#
# The two names above are STABLE names chosen here, not what the tool writes: both
# boxes come out with a per-run suffix appended before the extension
# (`edger_output_project_<id>_<date>_<6 random chars>.box`), whose last characters are
# random and therefore impossible to predict. The rule resolves each by glob and
# renames it, so downstream steps and `rule all` can refer to a fixed path.


rule edger:
    shell:
        r"""
        (
            mkdir -p "{params.outdir}"
            omicsbox edger \
                --i-count-table="{input.count_table}" \
                --i-file-design-table="{input.design}" \
                --local-folder="{params.outdir}" \
                {params.args}

            # Both boxes carry an unpredictable per-run suffix; resolve each by glob and
            # rename to the stable name the workflow declared.
            mv "$(find "{params.outdir}" -maxdepth 1 -name 'edger_output_project_*.box' | head -n1)" "{output.results}"
            mv "$(find "{params.outdir}" -maxdepth 1 -name 'edger_summary_report_*.box' | head -n1)" "{output.report}"
        ) >{log} 2>&1
        """
