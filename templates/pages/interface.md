---
id: <interface-id>
title: What contract does this repo expose or consume for <surface>?
kind: interface
status: current
maintainer: agent
sources:
  - schema/<contract>.schema.json
  - url:https://example.com/contract-home
verified:
  commit: 0000000
  date: 2026-01-01
links:
---
One paragraph naming the contract, its version, and whether this repo produces
or consumes it. Point at the schema and the dispensa id — do not restate the
field list, which lives in the contract itself.

## Pointers

- Schema: cite the file under sources.
- dispensa: reference the relevant Q-id or ADR in plain text (never `[[...]]`).
- Version pinned by this repo, and where that pin lives.
