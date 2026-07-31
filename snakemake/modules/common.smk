# =============================================================================
# FILE: modules/common.smk
# Shared path/config helpers for every OmicsBox Snakemake workflow. Defines NO
# rules (and, deliberately, NO shell-command builders - each module writes its own
# self-contained `shell:` block, so a module file depends on nothing here).
#
# Used in the WORKFLOW when wiring each step with `use rule <op> as <step> with:`
# (workflow scope, where OUTDIR and config are defined): stage, join_args, logfile,
# require, optional_input, expand_braces, reads_pattern, raw_reads, single_end.
#
# A workflow `include:`s this file once (alongside the module files it uses), so
# its `use rule ... as ... with:` overrides can reach these helpers.
# =============================================================================

import glob
import os
import re

from snakemake.exceptions import WorkflowError


# -----------------------------------------------------------------------------
# Per-rule argument injection.
#
# Joins a step's flag list from config.yaml (`<step>.args`) into the string appended
# to its `omicsbox` call. A YAML list, so an individual flag can be disabled by
# commenting it out with `#`. `None`/empty entries are dropped.
# -----------------------------------------------------------------------------
def join_args(key):
    entries = (config.get(key, {}) or {}).get("args", []) or []
    return " ".join(str(a) for a in entries if a not in (None, ""))


# -----------------------------------------------------------------------------
# Output-directory helper.
#
# `stage(key)` -> the numbered folder for a step (e.g. results/<run>/02_diamond_blast).
# Each step declares its exact output filename(s) with `os.path.join(stage("X"),
# "<name>.box")`, and passes `stage("X")` again as `params.outdir` for OmicsBox's
# `--local-folder`. These paths are deterministic (no per-run hash), which is what
# lets Snakemake resume a run and skip already-computed steps.
# -----------------------------------------------------------------------------
def stage(key):
    return os.path.join(OUTDIR, config[key]["outdir"])


# Per-rule log file (all stdout/stderr of a step is captured here).
def logfile(name):
    return os.path.join(OUTDIR, "logs", f"{name}.log")


# -----------------------------------------------------------------------------
# Required-parameter guard.
#
# CALL THIS ONLY FROM INSIDE A LAZY `input:`/`params:` FUNCTION, never at parse
# time. Raising while the Snakefile is being read would abort EVERY target,
# including ones that do not need the parameter (`dump_config` must still work
# with the shipped `input_fasta: null` default). A lambda defers the call to
# DAG-build time, and Snakemake only evaluates input functions for rules that are
# actually in the requested DAG, so `dump_config` stays unaffected:
#
#     fasta=lambda wc: os.path.abspath(require("input_fasta", "the input FASTA"))
#
# "Missing" means None or a blank string; 0 / False are returned as-is, so this is
# safe for numeric or boolean required parameters too.
# -----------------------------------------------------------------------------
def require(key, hint=None):
    value = config.get(key)
    if value is None or (isinstance(value, str) and not value.strip()):
        raise WorkflowError(
            f"Missing required parameter '{key}'."
            f" Pass it with  --config {key}=<value>  or set it in your --configfile."
            + (f"\n  ({hint})" if hint else "")
        )
    return value


# -----------------------------------------------------------------------------
# Optional-file-input helper.
#
# `optional_input(key)` -> an absolute-path singleton list if `config[key]` is set,
# else an empty list. An empty list means "no file here": the step's `input:` gets a
# valid (empty) value so `dump_config` still parses, and the step's `params:` builds
# the matching `--i-*` flag as an empty string when the list is empty.
# -----------------------------------------------------------------------------
def optional_input(key):
    value = config.get(key)
    return [os.path.abspath(value)] if value else []


# -----------------------------------------------------------------------------
# Brace expansion for glob patterns.
#
# Python's `glob` does not understand shell-style brace alternation
# (`data/*_{1,2}.fastq.gz`): passed straight through, `{1,2}` is matched as a
# literal string, not an alternation, so it silently matches nothing.
# `expand_braces` expands the single brace group (if any) into one pattern per
# option before globbing; a pattern with no braces is returned unchanged (already
# valid glob syntax).
# -----------------------------------------------------------------------------
def expand_braces(pattern):
    m = re.search(r"\{([^{}]+)\}", pattern)
    if not m:
        return [pattern]
    prefix, suffix = pattern[: m.start()], pattern[m.end() :]
    return [prefix + opt + suffix for opt in m.group(1).split(",")]


# -----------------------------------------------------------------------------
# Raw-reads resolution: `input_single_end` / `input_paired_end` are repo-wide
# config keys - every reads-consuming workflow uses these two names - so they are
# fixed here rather than passed in like `require()`'s key.
#
# `reads_pattern()` enforces that exactly one of the two is given - it is also what
# tells the tools whether to expect read pairs. `raw_reads()` resolves that pattern
# to a sorted file list, expanding brace alternation first. Both raise via
# `WorkflowError` and must only be called from inside a lazy `input:`/`params:`
# function (see `require()` above) so `dump_config` keeps working with the shipped
# null defaults.
# -----------------------------------------------------------------------------
def reads_pattern():
    single, paired = config.get("input_single_end"), config.get("input_paired_end")
    if single and paired:
        raise WorkflowError(
            "Give either input_single_end or input_paired_end, not both."
        )
    if not (single or paired):
        raise WorkflowError(
            "No reads given. Pass a glob with  --config input_single_end=<glob>  "
            "or  --config input_paired_end=<glob>"
        )
    return single or paired


def raw_reads(wildcards=None):
    matches = []
    for pattern in expand_braces(os.path.abspath(reads_pattern())):
        matches.extend(glob.glob(pattern))
    if not matches:
        raise WorkflowError(f"No reads matched the pattern: {reads_pattern()}")
    return sorted(matches)


# "true"/"false" string for a step's `params:` (e.g. `--i-fastq-files-single-end` vs
# `-paired-end`), derived from the same `input_single_end` convention as above.
def single_end():
    return "true" if config.get("input_single_end") else "false"
