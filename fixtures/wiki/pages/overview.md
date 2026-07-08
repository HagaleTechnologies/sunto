---
id: overview
title: skimmer — what is this and where do things live?
kind: overview
status: current
maintainer: agent
sources:
  - README.md
  - crates/**/*.rs
verified:
  commit: 0b5029d
  date: 2026-07-05
links:
  - dsp-pipeline
  - hot-loop
---
skimmer is a fixture repo used to exercise sunto's wiki-lint. This overview
answers "where do things live" and points at the subsystem pages rather than
restating any normative content.

## Layout

- `crates/skimmer-dsp/` — the DSP pipeline; see [[dsp-pipeline]].
- `src/hot_loop.rs` — the sample-processing hot loop; see [[hot-loop]].
- `docs/` — normative constants and design notes (the wiki points, never copies).

## Where to start

Read the subsystem pages before deep exploration. Window constants and
thresholds are defined in docs/ — this wiki cites them, it does not restate.
