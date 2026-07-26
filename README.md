# OmicsBox Engine Workflows

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A525.04.0-23aa62.svg)](https://www.nextflow.io/)
[![Snakemake](https://img.shields.io/badge/snakemake-%E2%89%A59.23.0-039475.svg)](https://snakemake.readthedocs.io/)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A collection of [Nextflow](https://www.nextflow.io/) and [Snakemake](https://snakemake.readthedocs.io/) pipelines that orchestrate the **OmicsBox Engine CLI**. Each workflow wires together a sequence of `omicsbox` commands into a reproducible pipeline; OmicsBox itself runs the heavy bioinformatics analyses in the cloud and handles parallelization, resource allocation and input validation, while these workflows take care of sequencing the steps, wiring inputs/outputs together and laying out the results. To ensure a seamless user experience, every pipeline is driven by a self-documenting configuration template. You can easily customize any underlying OmicsBox parameter or advanced option simply by filling in or uncommenting pre-defined flags directly in the config file, without needing to memorize complex CLI syntax.

## Prerequisites

- [Nextflow](https://www.nextflow.io/) `v25.04.0` or later — to run the pipelines under [`nextflow/`](nextflow/)
- [Snakemake](https://snakemake.readthedocs.io/) `v9.23.0` or later — to run the pipelines under [`snakemake/`](snakemake/)
- OmicsBox Engine CLI (`omicsbox`) — installed, licensed, and available on `PATH`

## Quick Start

There are two ways to run any of these pipelines: **cloning the repository and running the workflow locally** (the one shown below), or running it **directly from GitHub without cloning**. See the [Wiki](wiki) for the full breakdown of both options.

The commands below only fetch each workflow's configuration template and exit — no OmicsBox cloud job is launched, so no credentials or cost are involved. Replace `<workflow>` with the name of any pipeline from the list below.

**Nextflow**

```bash
git clone https://github.com/BioBam/omicsbox-engine-workflows.git
cd omicsbox-engine-workflows
nextflow run nextflow/workflows/<workflow>/<workflow>.nf --dump_config
```

**Snakemake**

```bash
git clone https://github.com/BioBam/omicsbox-engine-workflows.git
cd omicsbox-engine-workflows
snakemake -s snakemake/workflows/<workflow>/Snakefile dump_config --cores 1
```

---

**For the full parameter reference, cluster installation guides, and biological background, see our [Wiki](wiki).**
