# skimmer wiki index

- [skimmer — what is this and where do things live?](pages/overview.md) — skimmer is a fixture repo used to exercise sunto's wiki-lint. This overview
- [How is the DSP pipeline staged and why?](pages/dsp-pipeline.md) — The DSP pipeline is a staged chain: decimation, polyphase filter bank, then
- [How does the sample hot loop stay allocation-free?](pages/hot-loop.md) — The hot loop pulls IQ samples from a preallocated ring buffer and never
- [Why is the spot stream newline-delimited JSON, not protobuf?](pages/spot-format-decision.md) — The spot stream is newline-delimited JSON for debuggability and easy consumer
- [Why does SKIMMER_THREADS=0 silently disable detection?](pages/config-gotcha.md) — Setting `SKIMMER_THREADS=0` parses as "auto" on some platforms and "disabled" 🔒
- [How do I deploy skimmer to the receiver host?](pages/deploy-runbook.md) — Deploy is a two-step procedure: push the release binary, then restart the
- [Can the detector threshold adapt without a full recalibration pass?](pages/open-detector-question.md) — Open question: we do not yet know whether the detector threshold can adapt [draft]
