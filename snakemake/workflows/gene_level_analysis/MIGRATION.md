# Gene-Level Analysis — Nextflow → Snakemake migration notes

Developer notes for the Snakemake port of the Nextflow `gene_level_analysis` pipeline
(`omicsbox-engine-workflows/nextflow/workflows/gene_level_analysis/`).

For the general design (the `include:`-per-module layout, `use rule … as … with:`,
`rules.<step>.output` wiring, config layering, `OUTDIR`/`run_id`, the absolute-path
requirement, the `require()` guard, optional inputs, and `rule all` as the switchboard)
see the canonical [`../functional_annotation/MIGRATION.md`](../functional_annotation/MIGRATION.md)
§3.1/§3.4/§3.8/§3.11/§3.12/§3.13/§3.14/§3.17. This document covers only what is specific
to `gene_level_analysis`.

## 1. Shape

Seven steps, six distinct tools (`fastqc` is instantiated twice):

| step | operation | outdir | input edges |
|---|---|---|---|
| `fastqc_raw` | `fastqc` | `01_fastqc_raw` | raw reads glob (+ optional adapters/contaminants) |
| `trimmomatic_step` | `trimmomatic` | `02_trimmomatic` | raw reads glob (+ optional adapters) |
| `fastqc_post` | `fastqc` | `03_fastqc_post` | `trimmomatic` folder |
| `star` | `star_aligner` | `04_star` | `trimmomatic` folder + genome FASTA + annotation |
| `htseq_step` | `htseq` | `05_htseq` | `star` folder (BAMs) + annotation |
| `counts_pca_step` | `counts_pca` | `06_counts_pca` | HTSeq count table (+ optional design) |
| `edger_step` | `edger` | `07_edger` | HTSeq count table + design |

Four steps carry the `_step` suffix because their natural name equals their base rule
name (`trimmomatic`, `htseq`, `counts_pca`, `edger`). `star` does **not** — its operation
is `star_aligner`, so there is no collision. Both QC steps are leaves; the Nextflow
workflow never consumes their output either.

**Reused as-is:** `fastqc.smk`, `trimmomatic.smk`, `counts_pca.smk`, `edger.smk` — all
four already existed for `transcript_level_analysis`.
**New for this pipeline:** `modules/transcriptomics/star.smk`, `modules/transcriptomics/htseq.smk`.

This pipeline is the gene-level sibling of `transcript_level_analysis`: same
QC → trimming → QC front end and same PCA/edgeR back end, with STAR + HTSeq
(align to the genome, then count per gene) replacing RSEM (quantify against a
transcriptome). Consequences: it needs a genome annotation (`input_gff`) that
`transcript_level_analysis` has no use for, and it has **no** gene/transcript-level
switch — the level is fixed by the tool choice, so there is no `rsem_gene_level`
equivalent and no conditional count-table selection.

## 2. Reads

Identical to `transcript_level_analysis` §2 — see that file. In short:
`raw_reads`/`single_end` from `common.smk` resolve the `input_single_end` /
`input_paired_end` globs (mutually exclusive, one mandatory), `expand_braces` handles
the `{1,2}` alternation Python's `glob` does not understand, and `star.smk` accepts
either a literal FASTQ list or the upstream `directory()` output.

⚠️ **The read-pair pattern flags differ per tool and are not interchangeable.** STAR
takes plain `--upstream-pattern` / `--downstream-pattern`; `trimmomatic` spells them
`--upstream-pattern-preprocessing` / `--downstream-pattern-preprocessing`, and `rsem`
uses `--upstream-pattern-counts` / `--downstream-pattern-counts`. Each module hardcodes
its own spelling; the workflow only supplies the raw `up_pattern`/`down_pattern` values.

## 3. `input_gff` is consumed twice

The annotation goes to two steps for two different purposes: STAR uses it to build the
splice-junction database (so reads spanning junctions align correctly), and HTSeq uses it
to decide which feature each aligned read belongs to. A single `_annotation()` helper
feeds both, so the path is resolved and validated once.

Note it is a *required* input in both, so it goes through `require()` — unlike STAR's
`--provide-gff=true` flag in `args`, which is what tells the aligner to actually use the
annotation it was given.

## 4. STAR's output is one folder, and consumers must glob it

`OUTPUT_FILENAMES.md` records that STAR's **three folder parameters all collapse to the
same `--local-folder`**. With this pipeline's flags (`--save-splice-junctions=true`,
`--save-unmapped-reads=true`) that one folder ends up holding, side by side:

```
04_star/*_Aligned.sortedByCoord.out.bam   one per sample
04_star/*_SJ.out.tab                      one per sample
04_star/*_Unmapped.fastq.gz               one per sample
04_star/star_report.box
04_star/chart_abs_value.box
04_star/chart_rel_value.box
```

The step is therefore declared as `directory(stage("star"))` — the same treatment
`trimmomatic` gets, and for the same reason: the deliverable is a *set* of per-sample
files whose names the tool chooses and whose count varies with the sample count, so
there is no fixed list of names to declare.

The trade-off is deliberate but worth knowing: the three `.box` names **are** exact and
could have been declared individually, which would catch a run that silently produces
nothing. Mixing a `directory()` output with file outputs inside it in one rule is not
viable, and the BAMs are what the pipeline actually needs downstream, so the folder won.
If a future change makes those reports terminal deliverables in their own right, splitting
them out is the thing to reconsider.

**This is why `htseq.smk` globs `*.bam` specifically** rather than taking the folder
wholesale — the `.tab` and `.fastq.gz` files are not alignments, and passing them to
`--i-alignment-files` would be wrong.

## 5. `counts_pca_use_design`

Identical to `transcript_level_analysis` §4. `params.design_flag` carries both halves —
`--design=true` and `--i-experimental-design=<file>` — because the CLI rejects the file
argument when `--design=false`. `experimental_design` is still required overall, since
edgeR always needs it.

## 6. Output filenames

| step | declared | actually written | how |
|---|---|---|---|
| `fastqc_raw`/`fastqc_post` | `fastqc_report.box`, `quality_assessment.box` | both carry a per-run suffix | `find` + `mv` in `fastqc.smk` |
| `trimmomatic_step` | `directory(...)` | trimmed reads + suffixed report | folder is the deliverable |
| `star` | `directory(...)` | BAMs/junctions/unmapped + 3 exact `.box` | folder is the deliverable (§4) |
| `htseq_step` | `count_table.box`, `htseq_report.box` | exact, no suffix | — |
| `counts_pca_step` | `pca-plot.<chart_format>` | exact (chart title) | — |
| `edger_step` | `edger_output_project.box`, `edger_summary_report.box` | both carry a per-run suffix | `find` + `mv` in `edger.smk` |

HTSeq's two names come from `HtseqWorkflow.java:45-46` (`setValueFrom` → exact, no run
suffix); STAR's three `.box` names from `StarWorkflow.java:134-136`.

## 7. Not verified statically

Everything above is derived from the Engine source and checked with dry runs; no cloud job
was run. The output names come from `OUTPUT_FILENAMES.md` (statically derived from
`omicsbox-bnd`, with the source class cited per entry), so the first real run is what
confirms them.

Two things to watch on that first run, both in the new modules:

- **STAR's BAM filenames.** `OUTPUT_FILENAMES.md` gives the pattern as
  `*_Aligned.sortedByCoord.out.bam`, chosen by the cloud service rather than the CLI.
  `htseq.smk` only assumes the `.bam` extension, so a change in the sample-name prefix is
  harmless — but if the aligner ever emitted unsorted BAMs alongside sorted ones, the glob
  would pick up both.
- **HTSeq's `count_table.box`.** Declared as an exact literal on the strength of the
  `setValueFrom` call; if it turns out to carry a suffix after all, the fix is the
  `find`/`mv` pattern already used in `fastqc.smk` and `edger.smk`.
