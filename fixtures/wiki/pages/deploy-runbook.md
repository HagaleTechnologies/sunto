---
id: deploy-runbook
title: How do I deploy skimmer to the receiver host?
kind: runbook
status: current
maintainer: human
sources:
  - deploy/skimmer.service
  - scripts/deploy.sh
verified:
  commit: eeeeeee
  date: 2026-07-02
---
Deploy is a two-step procedure: push the release binary, then restart the
systemd unit. This runbook captures the steps the second time someone runs
them, so nobody reconstructs it from scratch.

## Steps

1. Build the release binary and copy it to the receiver host.
2. `systemctl restart skimmer` and confirm spots resume within 30s.

## Rollback

Keep the previous binary; swap it back and restart if spots do not resume.
