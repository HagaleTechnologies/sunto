---
id: spot-format-decision
title: Why is the spot stream newline-delimited JSON, not protobuf?
kind: decision-digest
status: current
maintainer: agent
sources:
  - docs/adr/0004-spot-format.md
  - url:https://ndjson.org/
verified:
  commit: ddddddd
  date: 2026-01-01
---
The spot stream is newline-delimited JSON for debuggability and easy consumer
tooling; the full rationale is in the ADR cited under sources. This page's
`verified.date` is intentionally old (2026-01-01) so WK-W12 fires against it.

## Digest

NDJSON trades a little bandwidth for line-oriented tooling and human-readable
capture files. The decision and its trade-off table are normative in the ADR;
this digest only points there.
