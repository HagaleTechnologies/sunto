## Multi-agent hygiene

You are never alone in this repo — other agents may be working concurrently
in other clones, branches, or worktrees.

- **Start fresh:** `git fetch` and rebase onto `origin/main` before reading
  code or making decisions; stale context produces wrong work.
- **Claim before work:** search open PRs/issues first; open a draft PR early —
  the draft PR *is* the claim. Don't duplicate in-flight work.
- **Isolate:** always a branch (worktree preferred), never a shared checkout's
  main. Use per-session scratch dirs; don't bind fixed ports.
- **Flush at the end:** push (`--force-with-lease` only) and open/update your
  PR before finishing. Unpushed work is invisible work.
- **Main moves only by PR merge.**


## Code review convergence

Every review round fixes P1 findings inline. From round 2 onward, P2-and-
lower findings are not fixed inline — they're captured verbatim into a
follow-up ticket instead, so the PR converges instead of chasing
progressively finer findings across rounds. Round 1 is unrestricted (fix
everything reasonable). Full policy:
docs/DECISIONS/2026-08-07-pr-review-convergence-policy.md.
