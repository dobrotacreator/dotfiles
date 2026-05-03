# Dotfiles

Personal dotfiles managed with GNU Stow.

## Install

Clone this repository into your home directory, then run:

```sh
stow .
```

This symlinks the dotfiles from this repository into the parent directory,
usually `$HOME`.

To preview changes first:

```sh
stow --simulate --verbose .
```

Repository-only files such as this README and helper scripts are excluded by
`.stow-local-ignore`.

## AI Agent Config

Shared coding-agent instructions live in `.config/ai/AGENTS.md`.

Claude Code and Codex load that file through small entrypoints:

- `.claude/CLAUDE.md`
- `.codex/AGENTS.md`

Portable Claude Code hooks are kept in `.claude/hooks/`.
The Claude Code status line script is kept in `.claude/statusline.sh`.
Portable Codex hooks are kept in `.codex/hooks/`, with `.codex/hooks.json`
enabling the destructive-op guard.

Agent runtime settings that contain local state, such as `~/.codex/config.toml`
and `~/.claude/settings.json`, are kept live-local.
Portable baseline templates for those live-local files are kept in
`.config/ai/templates/`.
