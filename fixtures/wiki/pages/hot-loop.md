---
id: hot-loop
title: How does the sample hot loop stay allocation-free?
kind: subsystem
status: current
maintainer: agent
sources:
  - src/hot_loop.rs
  - url:https://example.com/ringbuffer-spec
verified:
  commit: aaaaaaa
  date: 2026-07-05
---
The hot loop pulls IQ samples from a preallocated ring buffer and never
allocates on the sample path. This is the designated candidate-stale page:
`fixtures/setup.sh` touches `src/hot_loop.rs` after the verified commit so
WK-W11 fires against it.

## Why allocation-free

Allocations on the sample path cause dropped buffers under load. The buffer
sizing rationale lives in docs/ — see the ring-buffer spec cited in sources.

## Gotcha pointer

Backpressure handling has a footgun; see the config gotcha page.
