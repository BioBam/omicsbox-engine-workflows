# Genetic Variation Analysis — Nextflow → Snakemake migration notes

Developer notes for the Snakemake port of the Nextflow `genetic_variation_analysis`
pipeline (`omicsbox-engine-workflows/nextflow/workflows/genetic_variation_analysis/`).

For the general design (the `include:`-per-module layout, `use rule … as … with:`,
`rules.<step>.output` wiring, config layering, `OUTDIR`/`run_id`, the absolute-path
requirement, the `require()` guard, optional inputs, and `rule all` as the switchboard)
see the canonical [`../functional_annotation/MIGRATION.md`](../functional_annotation/MIGRATION.md)
§3.1/§3.4/§3.8/§3.11/§3.12/§3.13/§3.14/§3.17. This document covers only what is specific
to `genetic_variation_analysis`.

## 1. Shape

Nine steps, eight distinct tools (`fastqc` is instantiated twice) — the longest pipeline
in the repo so far:

| step | operation | outdir | input edges |
|---|---|---|---|
| `fastqc_raw` | `fastqc` | `01_fastqc_raw` | raw reads glob (+ optional adapters/contaminants) |
| `trimmomatic_step` | `trimmomatic` | `02_trimmomatic` | raw reads glob (+ optional adapters) |
| `fastqc_post` | `fastqc` | `03_fastqc_post` | `trimmomatic` folder |
| `bwa_step` | `bwa` | `04_bwa` | genome FASTA + `trimmomatic` folder |
| `bcftools` | `variantcalling_multipackage` | `05_variant_calling` | `bwa` folder (BAMs) + genome FASTA (+ optional group file) |
| `variant_filtering` | `variant_filtering_freebayes` | `06_variant_filtering` | `bcftools` VCF |
| `beagle_step` | `beagle` | `07_beagle` | `variant_filtering` VCF |
| `gwas_step` | `gwas` | `08_gwas` | `beagle` VCF + traits table (+ optional kinship/covariate) |
| `variant_annotation_step` | `variant_annotation` | `09_variant_annotation` | **`variant_filtering` VCF** + annotation GTF + genome FASTA |

Five steps carry the `_step` suffix (`trimmomatic`, `bwa`, `beagle`, `gwas`,
`variant_annotation`). `bcftools` and `variant_filtering` do **not**: their operations are
`variantcalling_multipackage` and `variant_filtering_freebayes`, so the step names do not
collide.

**Reused as-is:** `fastqc.smk`, `trimmomatic.smk`.
**New for this pipeline:** `bwa.smk` (in a new `modules/genome_analysis/`), plus
`bcftools.smk`, `variant_filtering.smk`, `beagle.smk`, `gwas.smk` and
`variant_annotation.smk` (in a new `modules/genetic_variation/`).

Both new module folders mirror the upstream layout, as the six existing ones do — the
category was not a judgement call.

## 2. The one wiring decision that is not the obvious one

`variant_annotation_step` reads the **filtered** VCF from step 06, not the phased/imputed
VCF from step 07, even though step 07 sits between them in the pipeline.

The upstream `.nf` explains why, and it is worth restating because it looks like a
mis-wire: annotation cross-references the variant file against the genome, which needs the
file to still declare the same sequences. Phasing/imputation strips the VCF's `##contig`
headers and drops unplaced scaffolds, so its output no longer matches the genome and
OmicsBox rejects it. The filtered VCF still carries bcftools' `##contig` headers.

So the DAG forks at step 06: one branch goes 06 → 07 → 08 (phasing → association study),
the other goes 06 → 09 (annotation). Verified in the rendered commands — the annotation
step reads `06_variant_filtering/dir-save.vcf.gz`, the association study reads
`07_beagle/out.vcf.gz`.

A user-facing version of this note is in the Snakefile at step 09, in the pipeline's own
terms.

## 3. Reads

`raw_reads`/`single_end` from `common.smk`, as in the other read-consuming pipelines.
`bwa` uses plain `--upstream-pattern`/`--downstream-pattern` (the same spelling as
`megahit` and `star-aligner`, not `trimmomatic`'s `-preprocessing` suffix).

## 4. The reference genome is shared by three steps

`input_fasta` feeds the alignment, the variant calling and the annotation. One
`_reference()` helper serves all three, so the path is resolved and validated once and all
three necessarily see the same file — which matters, because a variant file only makes
sense against the genome it was called from.

## 5. Three optional inputs, each paired with a switch

| config key | switch in `args` | step |
|---|---|---|
| `bcftools_group_experiment` | `--use-groups` | variant calling |
| `gwas_kinship` | `--use-kinship` | association study |
| `gwas_covariate_matrix` | `--use-covariate-matrix` | association study |

Each is a two-sided setting: the file without the switch is ignored, the switch without
the file leaves the step with nothing to read. Both halves are documented at each end in
`config.yaml`, and the upstream config notes two extra couplings worth keeping in mind —
`--use-kinship=true` makes the three `--kinship-*` flags irrelevant, and
`--use-covariate-matrix=true` makes `--pcas` irrelevant.

`gwas_input_pheno` and `variant_annotation_annotation` are **required**, not optional, so
they go through `require()` rather than `optional_input()`.

## 6. Output filenames

Every tool in `genetic_variation/` is legacy, so none of their names carries a run suffix
— all of them are exact. That makes this the first pipeline where no step needs the
`find`/`mv` treatment except the two `fastqc` instances.

| step | declared | notes |
|---|---|---|
| `fastqc_raw`/`fastqc_post` | `fastqc_report.box`, `quality_assessment.box` | run-suffixed → `find` + `mv` in `fastqc.smk` |
| `trimmomatic_step` | `directory(...)` | folder is the deliverable |
| `bwa_step` | `directory(...)` | per-sample BAMs + `bwa_report.box`, `bwa_chart_abs.box`, `bwa_chart_rel.box` |
| `bcftools` | `dir-save.vcf.gz`, `Variant_Calling_Report.box` | charts left undeclared (see below) |
| `variant_filtering` | `dir-save.vcf.gz`, `Variant_Filtering_Report.box` | charts left undeclared (see below) |
| `beagle_step` | `out.vcf.gz`, `Beagle_Report.box` | — |
| `gwas_step` | `gwas_results.box`, `gwas_report.box` | normalized phenotype table left undeclared (see below) |
| `variant_annotation_step` | `Variant_Annotation_Table.box`, `Variant_Annotation_Report.box` | types chart left undeclared (see below) |

Sources: `BwaWorkflow.java:128-130`, `ConstantNames.java:4-6` (the bcftools chart titles),
`BeagleParameters.out` (→ `out.vcf.gz`), `GwasJob.java:95-97`,
`VariantAnnotationJob.java:149`.

Note `bcftools` and `variant_filtering` both write a file called `dir-save.vcf.gz` — they
are only distinguishable by their step folder, which is why the wiring goes through
`rules.<step>.output.vcf` rather than any shared constant.

### What is deliberately left undeclared, and why

A Snakemake `output:` is a hard assertion: the step fails if the file is absent. Four
things here are conditional or ambiguous, so declaring them would turn a normal run into a
failure.

* **The bcftools and variant-filtering charts.** Which charts exist is decided by the
  **content of the incoming VCF**, not by any flag. `VariantFilteringUtils.java:87-115`
  switches on the INFO field it finds (`DP`, `QUAL`, `QUALAO`, `QUALDP`, `MQM`, `MQ`, `MAF`)
  and builds a chart per field present; `VariantFilteringJob.java:247-266` then publishes
  only the ones whose title it recognises. A VCF missing an INFO field simply produces no
  chart for it, and that is not knowable statically.

  That same switch is also why the mapping-quality chart has two possible titles: `MQM`
  (freebayes) → *"Mapping Quality in Alternate Alleles"*, `MQ` (bcftools) → *"Average
  Mapping Quality"*. In **this** pipeline the VCF always comes from bcftools, so it would
  be the second one — the ambiguity is a property of the tool, not a live risk here. The
  binding reason for leaving these undeclared is the data-dependence above.

  Both upstream modules now declare these charts `optional: true`, which matches the
  behaviour above — `bcftools.nf` was made optional as part of this port, since by that
  code it would otherwise fail on a VCF that yielded no depth/quality chart.
* **Two files GWAS writes into an `output/` sub-folder inside its step directory**: the
  normalized phenotype table (`corrected_phenotype_data.txt.gz` / `.txt`, written whenever
  `--normalize=true` or `--remove-outliers=true` — this pipeline defaults to
  `--normalize=true`, so it is written by default) and the covariate matrix
  (`covariate_matrix.txt`, only with `--use-covariate-matrix=true`).

  `GwasParameters.output` (`GwasParameters.java:184`) is a `FileKey` validated as
  `existingFolder()`. GWAS is a **legacy** job (`GwasJob extends B2GJob`), and legacy
  folder-output keys are defaulted by
  `LegacyActionExecutor.injectFileOutputKeyDefaults` (`LegacyActionExecutor.java:636-646`)
  to `<local-folder>/<kebab(key-id)>/` — here `<local-folder>/output/` — not to
  `--local-folder` itself. That is a *different* rule from the one `WJob`-executed
  folder outputs follow (§1.4/§8 elsewhere in `OUTPUT_FILENAMES.md`, and the
  `WJobExecutor.applyRunDirDefault` codepath), which **does** collapse to
  `--local-folder`. `OUTPUT_FILENAMES.md` originally described gwas using the WJob rule;
  it has been corrected to the legacy one, confirmed against `LegacyActionExecutor`
  directly.

  Both files are left undeclared here regardless: each depends on a flag the user can
  flip, and nothing downstream reads either of them.
* **The variant-annotation types chart.** This step is not given a chart-format flag, so
  its extension follows the tool's own default rather than the pipeline's `chart_format`
  setting. Declaring it would hardcode an assumption about that default. (Worth noting the
  upstream module's `*[Tt]ypes*.box` glob makes the same assumption implicitly.)

All four still land in their step folders; they are just not part of the DAG contract.

## 7. Not verified statically

Everything above is derived from the Engine source and checked with dry runs; no cloud job
was run. The output names come from `OUTPUT_FILENAMES.md` (statically derived from
`omicsbox-bnd`, with the source class cited per entry), so the first real run is what
confirms them.

Things to watch on that first run:

- **`dir-save.vcf.gz` for both variant steps.** The name comes from a `dir-save` parameter
  key rather than anything descriptive, and it is the backbone of the whole downstream
  chain — if either differs, three steps lose their input at once.
- **`bwa`'s per-sample BAM filenames.** The module globs `*.bam` from the step folder, so
  the sample-name prefix does not matter; but if the aligner ever wrote an unsorted BAM
  alongside the sorted one, the glob would pick up both.
- **Whether the four undeclared outputs above actually appear**, and in what form. None of
  them can break the run as things stand, which is the point — but confirming them is what
  would let the charts be declared properly later.
