# --- FILE: modules/utilities/combine_projects.smk ---
# Wraps: omicsbox combine-projects - merges two OmicsBox projects into one.
#
# Generic, reusable rule (operation = `combine_projects`). Two inputs. Instantiate:
#   use rule combine_projects as <step> with:
#       input:  project1=<project A>, project2=<project B>
#       output: project=<step>/combined_project.box
#       params: outdir=stage("<step>"), args=join_args("<step>")
#       log:    logfile("<step>")
# The workflow decides which project maps to --i-project1 / --i-project2.


rule combine_projects:
    shell:
        r"""
        (
            omicsbox combine-projects \
                --i-project1="{input.project1}" \
                --i-project2="{input.project2}" \
                --local-folder="{params.outdir}" \
                {params.args}
        ) >{log} 2>&1
        """
