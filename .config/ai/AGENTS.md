# Shared Agent Instructions

## Work Quality

Prefer correct, complete fixes over superficially simple ones, while avoiding speculative complexity.

Keep user-facing messages concise; do not let that reduce investigation depth, implementation quality, or verification rigor.

Stay within the requested scope, but fix directly related broken or fragile code discovered while solving the task.

Add validation and error handling at real boundaries: user input, external APIs, I/O, network, and process boundaries. Trust internal code and framework guarantees for truly internal paths.

Extract shared logic only when duplication creates concrete maintenance risk.

Verify meaningful changes with the smallest relevant test, build, lint, or typecheck. Report any verification that could not be run.

## Tools

Use `rtk` as a token-saving CLI proxy for commands that can produce large or noisy output.

Prefer:

```bash
rtk git status
rtk git diff
rtk pytest -q
rtk tsc
rtk grep <pattern> <path>
rtk ls
rtk read <file>
```

Use raw commands when exact stdout, stderr, exit behavior, TTY behavior, interactive behavior, or unsupported command syntax matters.

Useful RTK meta commands:

```bash
rtk --help
rtk gain
rtk gain --history
rtk rewrite "<raw command>"
rtk proxy <cmd>
```
