#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path


def compact_number(value):
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None

    sign = "-" if number < 0 else ""
    number = abs(number)
    units = ["", "K", "M", "B"]
    unit = 0
    while number >= 1000 and unit < len(units) - 1:
        number /= 1000
        unit += 1

    if unit == 0:
        return f"{sign}{int(number)}"
    if number >= 100 or number.is_integer():
        return f"{sign}{int(number)}{units[unit]}"
    return f"{sign}{number:.1f}{units[unit]}"


def shorten_path(path):
    if not path:
        return "?"

    home = str(Path.home())
    path = os.path.normpath(path)
    if path == home:
        return "~"
    if path.startswith(home + os.sep):
        return "~" + path[len(home):]
    return path


def git_output(cwd, *args):
    if not cwd:
        return None

    try:
        result = subprocess.run(
            ["git", "-C", cwd, *args],
            capture_output=True,
            text=True,
            timeout=0.5,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None

    if result.returncode != 0:
        return None

    output = result.stdout.strip()
    return output or None


def git_branch(cwd):
    if git_output(cwd, "rev-parse", "--is-inside-work-tree") != "true":
        return None

    return (
        git_output(cwd, "symbolic-ref", "--quiet", "--short", "HEAD")
        or git_output(cwd, "rev-parse", "--short", "HEAD")
    )


def context_tokens(context):
    usage = context.get("current_usage") or {}
    if usage:
        total = (
            usage.get("input_tokens", 0)
            + usage.get("cache_creation_input_tokens", 0)
            + usage.get("cache_read_input_tokens", 0)
        )
        return total if total > 0 else None

    total = context.get("total_input_tokens")
    return total if isinstance(total, (int, float)) and total > 0 else None


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("Claude | ctx unknown")
        return

    model = (data.get("model") or {}).get("display_name") or (data.get("model") or {}).get("id") or "Claude"
    effort = (data.get("effort") or {}).get("level")
    model_part = f"{model} {effort}" if effort else model

    workspace = data.get("workspace") or {}
    cwd = workspace.get("current_dir") or data.get("cwd")
    cwd_part = shorten_path(cwd)
    git = git_branch(cwd)
    git_part = f" | git {git}" if git else ""

    context = data.get("context_window") or {}
    used = context.get("used_percentage")
    try:
        used_part = f"{float(used):.0f}%"
    except (TypeError, ValueError):
        used_part = "?"

    token_count = context_tokens(context)
    window = context.get("context_window_size")
    token_part = ""
    compact_used = compact_number(token_count)
    compact_window = compact_number(window)
    if compact_used and compact_window:
        token_part = f" ({compact_used}/{compact_window})"
    elif compact_window:
        token_part = f" (/{compact_window})"

    print(f"{model_part}{git_part} | ctx {used_part} used{token_part}")
    print(cwd_part)


if __name__ == "__main__":
    main()
