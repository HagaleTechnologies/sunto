---
id: dsp-pipeline
title: How is the DSP pipeline staged and why?
kind: subsystem
status: current
maintainer: mixed
sources:
  - crates/skimmer-dsp/**
verified:
  commit: bbbbbbb
  date: 2026-07-04
links:
  - hot-loop
---
The DSP pipeline is a staged chain: decimation, polyphase filter bank, then
detection. This page uses a glob source (`crates/skimmer-dsp/**`) to track the
whole crate for staleness.

## Stages

1. Decimate to the working sample rate.
2. Polyphase filter bank (oversampling factor is a normative constant in docs/).
3. Detection and spot emission, feeding [[hot-loop]] consumers downstream.

## Why staged

Staging keeps each step independently testable and lets the filter bank run at
its own rate without restating the window constants here.
