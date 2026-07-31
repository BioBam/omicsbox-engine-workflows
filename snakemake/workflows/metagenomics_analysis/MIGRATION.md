# Metagenomics Analysis — Nextflow → Snakemake migration notes

Developer notes for the Snakemake port of the Nextflow `metagenomics_analysis` pipeline
(`omicsbox-engine-workflows/nextflow/workflows/metagenomics_analysis/`).

For the general design (the `include:`-per-module layout, `use rule … as … with:`,
`rules.<step>.output` wiring, config layering, `OUTDIR`/`run_id`, the absolute-path
requirement, the `require()` guard, optional inputs, and `rule all` as the switchboard)
see the canonical [`../functional_annotation/MIGRATION.md`](../functional_annotation/MIGRATION.md)
§3.1/§3.4/§3.8/§3.11/§3.12/§3.13/§3.14/§3.17. This document covers only what is specific
to `metagenomics_analysis`.

## 1. Shape

Eight steps, seven distinct tools (`fastqc` is instantiated twice):

| step | operation | outdir | input edges |
|---|---|---|---|
| `fastqc_raw` | `fastqc` | `01_fastqc_raw` | raw reads glob (+ optional adapters/contaminants) |
| `trimmomatic_step` | `trimmomatic` | `02_trimmomatic` | raw reads glob (+ optional adapters) |
| `fastqc_post` | `fastqc` | `03_fastqc_post` | `trimmomatic` folder |
| `cont_rem_step` | `cont_rem` | `04_contaminant_removal` | `trimmomatic` folder (+ optional target genome) |
| `megahit_step` | `megahit` | `05_megahit` | `cont_rem` folder (clean reads only) |
| `prodigal_step` | `prodigal` | `06_prodigal` | `megahit` contigs |
| `pfam_scan_step` | `pfam_scan` | `07_pfam_scan` | `prodigal` genes |
| `eggnog_mapper_step` | `eggnog_mapper` | `08_eggnog_mapper` | `prodigal` genes |

Six steps carry the `_step` suffix because their natural name equals their base rule
name. Both QC steps are leaves; the Nextflow workflow never consumes their output either.

**Reused as-is:** `fastqc.smk`, `trimmomatic.smk`, `eggnog_mapper.smk`.
**New for this pipeline:** `cont_rem.smk`, `megahit.smk`, `prodigal.smk`, `pfam_scan.smk`
(all under `modules/metagenomics/`).

Only **two** guards, versus five in the gene/transcript-level pipelines: this workflow
takes no reference genome, annotation or design file, so `input_single_end` /
`input_paired_end` (mutually exclusive, one mandatory) are the only required inputs.

`eggnog_mapper.smk` is reused unchanged from `functional_annotation`, but fed a different
source: there it annotates the user's input FASTA, here it annotates the genes Prodigal
predicted from the assembly. Same `--i-type-options=genes`, so no module change was
needed.

## 2. Reads

`raw_reads`/`single_end` from `common.smk`, as in the other read-consuming pipelines.

⚠️ **Three different spellings of the read-pair pattern flags appear in this repo and are
not interchangeable.** `trimmomatic` and `cont-rem` both use
`--upstream-pattern-preprocessing` / `--downstream-pattern-preprocessing`; `megahit` and
`star-aligner` use plain `--upstream-pattern` / `--downstream-pattern`; `rsem` uses
`--upstream-pattern-counts`. Each module hardcodes its own; the workflow only supplies
the raw `up_pattern`/`down_pattern` values.

`cont-rem` and `megahit` also disagree on the *sequencing mode* flag:
`--sequencing=fastq_se|fastq_pe` for the former, `--sequencing=single|paired` for the
latter.

## 3. `megahit` takes ONE REPEATED FLAG PER READ FILE

Every other read-consuming tool in this repo takes a single comma-joined value
(`--i-fastq-files=a,b,c`). `megahit` is ported with the repeated form instead
(`--i-read-files=a --i-read-files=b …`, one occurrence per file), because that is what
the Nextflow module does, with the explicit comment *"OmicsBox megahit expects one
`--i-read-files` flag per file, repeated (not comma-joined)"*.

**The stated reason does not hold up, and the asymmetry is probably unnecessary.**
`MegahitParameters.readFiles` is a `MultipleFileKey`, and
`SpecBuilder.java:695` routes every `MultipleFileKey` to `buildMultiplePathOption(...)`,
which builds the option with `.arity("1..*")` **and** `.splitRegex(",")`
(`SpecBuilder.java:836-841`). A comma-separated value is therefore split by the parser
just as it is for `fastqc` — whose own module comment says as much (*"OmicsBox's PicoCLI
parser accepts space- or comma-separated file lists"*). Both forms are valid for this
parameter.

The repeated form is kept for fidelity to the upstream module, and it *is* accepted
(`arity("1..*")` covers repeated occurrences). But if the two implementations are ever
reconciled, comma-joining `megahit` would make it consistent with the other five
read-consuming modules at no cost. Verify against a real run before changing it — the
upstream comment may be recording a CLI behaviour that has since changed.

## 4. `reads_glob` — why `megahit` takes the glob as a parameter

`cont-rem` writes **both** read sets into its single output folder, one file per sample:

```
04_contaminant_removal/un_*.fq.gz              reads that did NOT match the target: the clean set
04_contaminant_removal/al_*.fq.gz              reads that DID match: the contaminants
04_contaminant_removal/cont_rem_report.box
04_contaminant_removal/cont_rem_chart_abs.box
04_contaminant_removal/cont_rem_chart_rel.box
```

Which sets exist depends on `--result-mode` (`only_other` by default, so normally just
`un_*`). The Nextflow module distinguishes them with two separate `emit:` channels
(`clean_reads` = `un_*.fq.gz`, `contaminant_reads` = `al_*.fq.gz`) and the workflow wires
`MEGAHIT(CONT_REM.out.clean_reads)`.

Snakemake has no `emit:`, and `cont_rem_step` is a single `directory()` output, so that
distinction has to be re-expressed somewhere. It lives in `megahit_step`'s
`params.reads_glob="un_*.fq.gz"`.

This is deliberately a parameter rather than a hardcoded glob in the module. The generic
extension glob the other reads modules use (`*.fq.gz`, …) would work with the default
`--result-mode=only_other` — but if a user switched it to `both`, that glob would silently
feed the contaminant reads into the assembly. The run would succeed and the contigs would
just be wrong, which is the worst possible failure mode. Naming the prefix explicitly
makes the step correct for every `--result-mode` value.

## 5. Output filenames

| step | declared | actually written | how |
|---|---|---|---|
| `fastqc_raw`/`fastqc_post` | `fastqc_report.box`, `quality_assessment.box` | both carry a per-run suffix | `find` + `mv` in `fastqc.smk` |
| `trimmomatic_step` | `directory(...)` | trimmed reads + suffixed report | folder is the deliverable |
| `cont_rem_step` | `directory(...)` | per-sample reads + 3 exact `.box` | folder is the deliverable (§4) |
| `megahit_step` | `megahit-contigs.fasta`, `megahit_report.box`, `nx-plot.<fmt>` | exact | — |
| `prodigal_step` | `faa.fasta`, `fna.fasta`, `gff.gff`, `prodigal_report.box`, 2 charts | exact | — |
| `pfam_scan_step` | `PfamScan_Annotations.box`, `PfamScan_Report.box` | exact | — |
| `eggnog_mapper_step` | `eggnog_annotations.box`, `eggnog_report.box` | both carry a per-run suffix | `find` + `mv` in `eggnog_mapper.smk` |

Sources: `ContRemWJob.java:103-105`, `AssemblerChart.java:67` (megahit's `Nx Plot` title),
`Charts.java:60,95` (prodigal's two chart titles), `PfamScanMetadata` (the mixed-case
`PfamScan_*` keys, spelled exactly as shown).

**`cont_rem_step` is a `directory()` for the same reason as `trimmomatic`/`star`:** the
deliverable is a *set* of per-sample files whose names the tool chooses and whose count
varies with the sample count. As with `star`, the three `.box` names **are** exact and
could have been declared individually to catch a run that silently produces nothing;
mixing a `directory()` output with file outputs inside it in one rule is not viable, and
the reads are what the pipeline needs downstream, so the folder won.

### `prodigal_log.box` — left undeclared on purpose

`OUTPUT_FILENAMES.md` lists a seventh Prodigal output, `prodigal_log.box`, derived from the
Engine's `outputs()` declaration, and flags that the Nextflow module omits it. This port
omits it too.

The reasoning: the Engine declaring it is not proof the CLI writes it, and the curated
Nextflow module — which has been exercised — does not expect it. A Snakemake `output:` is
a hard assertion, so declaring a file that never appears fails the step with
`MissingOutputException` on every run. Leaving it undeclared costs nothing (nothing
downstream reads it, and it stays in the folder if it is written), whereas declaring it
speculatively would break the pipeline if the Engine's declaration is the thing that is
wrong. If a real run shows it is written, adding it is a one-line change.

## 6. `cont_rem_target_genome` and `--target-index` must agree

The optional custom genome is a two-sided setting, and this is the one relation in this
pipeline that a user can get wrong silently:

* `cont_rem_target_genome` (top of `config.yaml`) supplies the FASTA;
* `--target-index` in the `cont_rem` `args` block chooses *which* genome to screen
  against — one of the built-in indexes, or `Create database from genome`.

Providing the FASTA without switching `--target-index` means the file is passed and
ignored; switching `--target-index` without the FASTA means there is nothing to build the
database from. Both halves are documented at each end in `config.yaml`.

Note `--target-index`'s default value contains spaces and parentheses
(`'Homo sapiens (grch38)'`), so it is carried in the YAML list as
`- "--target-index='Homo sapiens (grch38)'"` — outer double quotes for YAML, inner single
quotes preserved for the CLI.

## 7. Not verified statically

Everything above is derived from the Engine source and checked with dry runs; no cloud job
was run. The output names come from `OUTPUT_FILENAMES.md` (statically derived from
`omicsbox-bnd`, with the source class cited per entry), so the first real run is what
confirms them.

Three things to watch on that first run:

- **`cont-rem`'s per-sample read filenames.** `OUTPUT_FILENAMES.md` gives the prefixes as
  `un_`/`al_` with a `.fq.gz` extension; `megahit_step`'s `reads_glob` assumes exactly
  `un_*.fq.gz`. If the extension differs (e.g. `.fastq.gz`), the glob returns nothing and
  the step fails loudly rather than assembling the wrong thing — which is the intended
  failure direction, but the glob is the thing to adjust.
- **Whether `prodigal_log.box` is written at all.** The Engine declares it, the Nextflow
  module does not expect it, and neither pipeline has exercised it. Undeclared here (§5),
  so either answer is safe — but worth a look in the step folder after a run.
- **`megahit`'s repeated `--i-read-files`.** The option spec accepts both the repeated
  and the comma-separated form (§3), so this is not a correctness risk — but it is the
  one place where this pipeline is deliberately inconsistent with the other five
  read-consuming modules, and a real run is what would settle whether the asymmetry
  should stay.
