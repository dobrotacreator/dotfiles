# AI Runtime Templates

These files are reference templates for local agent runtime settings that should
not be fully stowed into place.

Use them as a merge source for new machines or after resetting local state:

- `claude-settings.template.json` -> `~/.claude/settings.json`
- `codex-config.template.toml` -> `~/.codex/config.toml`

Do not blindly replace live config files. Claude Code and Codex write runtime
state, auth-adjacent metadata, plugin state, notice flags, migration counters,
session state, and machine-specific paths into their config directories.

## Claude Code

The template captures portable user preferences:

- bypass permissions by default
- shared RTK and destructive-operation hooks
- shared status line script
- auto-memory disabled
- thinking summaries enabled
- dangerous-mode warning prompt skipped
- desired plugin enablement and non-official marketplaces

Install desired plugins separately:

```sh
claude plugin install superpowers@claude-plugins-official
claude plugin install context7@claude-plugins-official

claude plugin marketplace add tirth8205/code-review-graph
claude plugin install code-review-graph@code-review-graph

claude plugin marketplace add warpdotdev/claude-code-warp
claude plugin install warp@claude-code-warp
```

## Codex

The template captures portable user preferences:

- default model and reasoning effort
- yolo-style approvals and sandbox settings
- trust all projects via `[projects."/"]`
- TUI theme and compact status line
- goals feature
- Context7 and code-review-graph MCP servers

MCP servers can also be added through the CLI:

```sh
codex mcp add context7 -- npx -y @upstash/context7-mcp
codex mcp add code-review-graph -- uvx code-review-graph serve
```

Keep local-only values out of templates, especially:

- auth and account metadata
- session/history/cache/telemetry state
- plugin caches
- notice and migration counters
- project-specific absolute paths
