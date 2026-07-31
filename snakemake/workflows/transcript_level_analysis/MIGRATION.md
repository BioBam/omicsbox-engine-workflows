# Transcript-Level Analysis — Nextflow → Snakemake migration notes

Developer notes for the Snakemake port of the Nextflow `transcript_level_analysis`
pipeline (`omicsbox-engine-workflows/nextflow/workflows/transcript_level_analysis/`).

For the general design (the `include:`-per-module layout, `use rule … as … with:`,
`rules.<step>.output` wiring, config layering, `OUTDIR`/`run_id`, the absolute-path
requirement, the `require()` guard, optional inputs, and `rule all` as the switchboard)
see the canonical [`../functional_annotation/MIGRATION.md`](../functional_annotation/MIGRATION.md)
§3.1/§3.4/§3.8/§3.11/§3.12/§3.13/§3.14/§3.17. This document covers only what is specific
to `transcript_level_analysis`.

## 1. Shape

Six steps, five distinct tools (`fastqc` is instantiated twice):

| step | operation | outdir | input edges |
|---|---|---|---|
| `fastqc_raw` | `fastqc` | `01_fastqc_raw` | raw reads glob (+ optional adapters/contaminants) |
| `trimmomatic_step` | `trimmomatic` | `02_trimmomatic` | raw reads glob (+ optional adapters) |
| `fastqc_post` | `fastqc` | `03_fastqc_post` | `trimmomatic` folder |
| `rsem_step` | `rsem` | `04_rsem` | `trimmomatic` folder + reference FASTA (+ optional transcript-to-gene map) |
| `counts_pca_step` | `counts_pca` | `05_counts_pca` | RSEM count table (+ optional design) |
| `edger_step` | `edger` | `06_edger` | RSEM count table + design |

Four steps carry the `_step` suffix because their natural name equals their base rule
name; `fastqc_raw`/`fastqc_post` do not collide, so they don't. Both QC steps are leaves
— the Nextflow workflow never consumes their output either.

`modules/transcriptomics/` (`rsem.smk`, `counts_pca.smk`, `edger.smk`) and
`modules/general_tools/fastqc.smk` were introduced for this pipeline;
`trimmomatic.smk` is reused as-is.

## 2. Reads: literal file list *or* an upstream directory

Nextflow feeds every read-consuming process a single already-resolved fileset: `ch_reads`
for `FASTQC_RAW`/`TRIMMOMATIC`, `TRIMMOMATIC.out.trimmed_reads` for `FASTQC_POST`/`RSEM`.
In Snakemake, `trimmomatic.smk`'s output is a whole `directory()` while the raw entry
point is a literal list of FASTQ paths, so `fastqc.smk` and `rsem.smk` accept **either**:
their shell checks `[ -d "{input.reads}" ]` and globs the folder root when it is a
directory (non-recursive, so trimmomatic's `unpaired/` sub-folder is skipped), otherwise
it comma-joins Snakemake's space-separated list.

`channel.fromPath(pattern).collect()` also understands brace alternation
(`data/*_{1,2}.fastq.gz`) natively and yields one flat list so a single OmicsBox task is
spawned (OmicsBox parallelises over samples internally). Python's `glob` does not
understand braces, so `_expand_braces()` expands the group before globbing and
`_raw_reads()` returns the sorted flat list. It is passed as an **input function** (not a
static value) so `dump_config` still parses with both patterns at their `null` default.

`input_single_end` / `input_paired_end` are mutually exclusive and one is mandatory —
that choice is also what tells the tools whether to expect read pairs (`SINGLE_END`, and
the `--upstream/downstream-pattern-*` flags on paired-end only). `_reads_pattern()`
raises a `WorkflowError` for "both" and for "neither", replacing the two Nextflow
`exit 1` guards; a third error covers a pattern matching no files, which Nextflow got
from `checkIfExists: true`.

## 3. `rsem_gene_level` — one switch, three effects

The Nextflow config keeps this in `params.rsem.gene_level` and deliberately **not** in the
step's `ext.args`, because the same value is read in three places. The port keeps that, as
the top-level `rsem_gene_level`:

1. it goes to the tool as `--gene-level=<bool>`;
2. it gates `--i-transcript-to-gene-file` (the map is only read in gene-level mode);
3. it selects **which count table the two statistics steps read** — `RSEM_COUNT_TABLE`
   resolves to `transcript_quantification_genes.box` or
   `transcript_quantification_isoforms.box` at parse time, because that choice is a DAG
   edge and must be known when the rules are defined.

RSEM writes the isoform table in both modes; in gene-level mode it stays in the step
folder untracked, since nothing consumes it. Same for the per-sample BAMs when
`--bam-output=true`.

**The guard.** Gene-level estimates are the sum of each gene's isoform estimates, so
without the transcript-to-gene map every reference sequence is its own gene and the gene
table comes back identical to the isoform one — a silent no-op. `_gene_trans_map()`
therefore raises if `rsem_gene_level` is on and `rsem_gene_trans_map` is unset. It raises
from an **input function** so the error surfaces at DAG-build time and `dump_config` still
parses even for a user whose config has gene level on.

## 4. `counts_pca_use_design` — optional here, mandatory in edgeR

edgeR's design file *is* the statistical model. For the PCA it only colours the plot, so
`counts_pca_use_design` lets you turn it off and inspect sample clustering without being
guided by the group labels.

`params.design_flag` carries **both halves** — `--design=true` and
`--i-experimental-design=<file>` — because the CLI rejects the file argument outright when
`--design=false`, so the two can never disagree. Off means the flag is the empty string.
This is why the Nextflow module injects `--design` from the process rather than leaving it
in `ext.args`.

`experimental_design` is still a required parameter (edgeR always needs it), so it goes
through `require()`.

## 5. Output filenames

Resolved from the repo-root [`OUTPUT_FILENAMES.md`](../../OUTPUT_FILENAMES.md). Three of
the five tools write names carrying a **per-run suffix**
(`<name>_<id>_<date>_<6 random chars>.box`) whose tail is random and cannot be
reconstructed, so those rules resolve each file by glob and rename it to a stable name:

| step | declared | actually written | how |
|---|---|---|---|
| `fastqc_raw`/`fastqc_post` | `fastqc_report.box`, `quality_assessment.box` | both suffixed | `find` + `mv` in `fastqc.smk` |
| `trimmomatic_step` | `directory(...)` | trimmed reads + suffixed report | the folder is the deliverable |
| `rsem_step` | `transcript_quantification_{isoforms,genes}.box` | exact | — |
| `rsem_step` | `transcript_quantification_report.box` | suffixed | `find` + `mv` in `rsem.smk` |
| `counts_pca_step` | `pca-plot.<chart_format>` | exact | — |
| `edger_step` | `edger_output_project.box`, `edger_summary_report.box` | both suffixed | `find` + `mv` in `edger.smk` |

Two notes worth keeping:

- **`counts_pca` is declared as a single file, not a `directory()`.** It writes exactly one
  chart, named after its title ("PCA Plot"), and the 2D and 3D variants share that title —
  so `--enable3d` does not change the name. An exact declaration makes a run that produces
  nothing fail instead of passing silently.
- **`fastqc` and `edger` outputs look like fixed literals in the Engine source.** Their
  `*FI.java` classes declare defaults such as `"fastqc_report.box"`, which is easy to read
  as the final name; the suffix is appended later because those inputs are declared with
  `BoxInput.fileInputName`. `OUTPUT_FILENAMES.md` §1.5 is the reference for that trap, and
  an earlier version of this port fell into it — it declared the suffixed names as plain
  literals, which would have failed every affected step with `MissingOutputException`.

## 6. Optional inputs

`fastqc_adapters`, `fastqc_contaminants`, `trimmomatic_adapters` and `rsem_gene_trans_map`
are flat top-level keys in the config's "WORKFLOW PARAMETERS" section rather than nested
under their step, so a user editing the dumped template sees them without scrolling to the
step blocks and can set them with `--config <key>=<path>`. Each resolves to `[]` when
unset, which leaves its flag out of the command; a real path is tracked, so its existence
is checked before anything runs.

`fastqc`'s two are paired flags — `--provide-adapters=true --i-adapters=<file>` — handled
inside `fastqc.smk`.

## 7. Not verified statically

Everything above is derived from the Engine source and checked with dry runs; no cloud job
was run. The output names come from `OUTPUT_FILENAMES.md` (statically derived from
`omicsbox-bnd`, with the source class cited per entry), so the first real run is what
confirms them — in particular the six `find`/`mv` globs, which fail loudly rather than
silently if a name differs.
