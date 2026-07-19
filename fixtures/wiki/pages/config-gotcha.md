---
id: config-gotcha
title: Why does SKIMMER_THREADS=0 silently disable detection?
kind: gotcha
status: current
maintainer: agent
locked: true
sources:
  - src/config.rs
verified:
  commit: ccccccc
  date: 2026-07-03
---
Setting `SKIMMER_THREADS=0` parses as "auto" on some platforms and "disabled"
on others, so detection silently stops. This page is `locked: true` to exercise
the locked-page flag in the manifest — agents must not edit it except to
re-stamp verified.

## Symptom

No spots emitted, no error logged. The thread-count default lives in docs/;
this page only records the footgun, not the value.

## Workaround

Set an explicit positive thread count.
