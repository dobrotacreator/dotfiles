#!/bin/bash
# ──────────────────────────────────────────────────────────────
# PreToolUse hook: blocks destructive and repository-altering operations.
# Claude must inform the user and ask them to run commands manually.
#
# Exit codes:  0 = allow,  2 = block with feedback
# ──────────────────────────────────────────────────────────────
set +e

# ── Configuration ────────────────────────────────────────────
# Local-only MCP plugins that never touch remote state.
# Add your own plugin names (substring match against tool_name).
MCP_LOCAL_PLUGINS="code-review-graph|context7"

# ── Parse input ──────────────────────────────────────────────
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)
cmd=$(echo "$input" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || true)

block() {
  echo "BLOCKED: $1" >&2
  echo "Inform the user what you intended to do and ask them to run it manually." >&2
  exit 2
}

# Regex anchor: matches command at line start or after a separator (; && || |)
SEP='(^|[;&|]+\s*)'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 1: Bash tool guards
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [[ -n "$cmd" ]]; then

  # ── Git: remote/push ──────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}git\s+push(\s|$)" \
    && block "git push — modifies the remote repository"

  # ── Git: destructive local operations ─────────────────────
  echo "$cmd" | grep -qE "${SEP}git\s+reset\s+--hard" \
    && block "git reset --hard — discards all uncommitted changes"
  echo "$cmd" | grep -qE "${SEP}git\s+checkout\s+--\s" \
    && block "git checkout -- — discards working tree changes"
  echo "$cmd" | grep -qE "${SEP}git\s+restore\s+[^-]*(\.|\*)(\s|$)" \
    && ! echo "$cmd" | grep -qE "git\s+restore\s+--staged" \
    && block "git restore — bulk discards changes"
  echo "$cmd" | grep -qE "${SEP}git\s+clean\s+-[a-zA-Z]*f" \
    && block "git clean -f — removes untracked files permanently"
  echo "$cmd" | grep -qE "${SEP}git\s+branch\s+.*-D(\s|$)" \
    && block "git branch -D — force-deletes branch without merge check"
  echo "$cmd" | grep -qE "${SEP}git\s+stash\s+(drop|clear)(\s|$)" \
    && block "git stash drop/clear — permanently discards stashed work"

  # ── Git: history rewriting ────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}git\s+rebase(\s|$)" \
    && ! echo "$cmd" | grep -qE "git\s+rebase\s+--(abort|continue|skip)" \
    && block "git rebase — rewrites commit history"
  echo "$cmd" | grep -qE "${SEP}git\s+merge(\s|$)" \
    && ! echo "$cmd" | grep -qE "git\s+merge\s+--abort" \
    && block "git merge — use pull requests instead"
  echo "$cmd" | grep -qE "${SEP}git\s+commit\s.*--amend" \
    && block "git commit --amend — rewrites the last commit"

  # ── Git: config/remote/tag modification ───────────────────
  echo "$cmd" | grep -qE "${SEP}git\s+remote\s+(add|remove|rm|set-url|rename)(\s|$)" \
    && block "git remote modification — alters remote configuration"
  echo "$cmd" | grep -qE "${SEP}git\s+tag\s+(-d|--delete)(\s|$)" \
    && block "git tag delete — removes tags"
  echo "$cmd" | grep -qE "${SEP}git\s+fetch\s+.*--prune" \
    && block "git fetch --prune — deletes remote-tracking branches"
  echo "$cmd" | grep -qE "${SEP}git\s+commit\s.*(-n\s|--no-verify)" \
    && block "git commit --no-verify — bypasses pre-commit hooks"

  # ── GitHub CLI: PR operations ─────────────────────────────
  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+merge(\s|$)" \
    && block "gh pr merge — merges a pull request"
  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+close(\s|$)" \
    && block "gh pr close — closes a pull request"
  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+(comment|review)(\s|$)" \
    && block "gh pr comment/review — posts visible content on a PR"
  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+create(\s|$)" \
    && block "gh pr create — creates a pull request"
  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+(edit|reopen)(\s|$)" \
    && block "gh pr edit/reopen — modifies a pull request"

  # ── GitHub CLI: issues, repos, releases ───────────────────
  echo "$cmd" | grep -qE "${SEP}gh\s+issue\s+(create|close|comment|edit|reopen|delete|transfer|pin|unpin)(\s|$)" \
    && block "gh issue write operation — modifies GitHub issues"
  echo "$cmd" | grep -qE "${SEP}gh\s+repo\s+(delete|archive|rename|edit)(\s|$)" \
    && block "gh repo destructive operation"
  echo "$cmd" | grep -qE "${SEP}gh\s+release\s+(create|delete|edit)(\s|$)" \
    && block "gh release modification — affects published releases"
  echo "$cmd" | grep -qE "${SEP}gh\s+(label|variable|secret)\s+(create|set|edit|delete)(\s|$)" \
    && block "gh label/variable/secret modification"

  # ── GitHub CLI: API + workflows + gists ───────────────────
  if echo "$cmd" | grep -qE "${SEP}gh\s+api\s"; then
    echo "$cmd" | grep -qE '(-X|--method)\s+(POST|PUT|PATCH|DELETE)' \
      && block "gh api with write method — modifies GitHub state"
  fi
  echo "$cmd" | grep -qE "${SEP}gh\s+workflow\s+run(\s|$)" \
    && block "gh workflow run — triggers a GitHub Actions workflow"
  echo "$cmd" | grep -qE "${SEP}gh\s+gist\s+(create|edit|delete)(\s|$)" \
    && block "gh gist write operation"

  # ── Package publishing ────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}(npm|pnpm|yarn)\s+publish(\s|$)" \
    && block "package publish — publishes to npm registry"
  echo "$cmd" | grep -qE "${SEP}npx\s+-y\s" \
    && block "npx -y — auto-installs remote packages without confirmation"
  echo "$cmd" | grep -qE "${SEP}bunx\s" \
    && block "bunx — auto-installs and runs remote package"

  # ── Destructive file operations ───────────────────────────
  echo "$cmd" | grep -qE "${SEP}rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+(/|\.\.|~|\\\$HOME|\.git)" \
    && block "rm -rf on sensitive path — potentially irreversible"
  echo "$cmd" | grep -qE "${SEP}rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+\.\s*$" \
    && block "rm -rf . — deletes everything in current directory"
  echo "$cmd" | grep -qE "${SEP}rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+\*" \
    && block "rm -rf * — deletes everything in current scope"

  # ── File truncation ───────────────────────────────────────
  echo "$cmd" | grep -qE '(^|[;&|]+\s*)>\s*/[^\s]' \
    && ! echo "$cmd" | grep -qE '(/dev/null|/tmp/)' \
    && block "file truncation with > — verify target file"

  # ── Database destructive operations ───────────────────────
  echo "$cmd" | grep -qiE "(dropdb|DROP\s+(DATABASE|TABLE|SCHEMA))" \
    && block "database drop operation — destroys data permanently"
  echo "$cmd" | grep -qiE "TRUNCATE\s+" \
    && block "TRUNCATE — deletes all rows permanently"
  echo "$cmd" | grep -qiE "DELETE\s+FROM\s+\w+\s*$" \
    && block "DELETE without WHERE — deletes all rows"
  echo "$cmd" | grep -qiE "ALTER\s+TABLE\s+.*\bDROP\b" \
    && block "ALTER TABLE DROP — removes columns/constraints"
  echo "$cmd" | grep -qE "${SEP}(psql|mysql|mongosh?|redis-cli)\s.*(-c|-e|--eval)\s" \
    && block "database CLI with inline command — verify before executing"

  # ── Docker ────────────────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}docker\s+(system\s+prune|container\s+rm|image\s+rm|volume\s+rm)" \
    && block "docker destructive operation — removes resources"
  echo "$cmd" | grep -qE "${SEP}docker\s+push(\s|$)" \
    && block "docker push — publishes image to registry"
  echo "$cmd" | grep -qE "${SEP}docker\s+(stop|kill)\s" \
    && block "docker stop/kill — stops running containers"
  echo "$cmd" | grep -qE "${SEP}docker\s+(rm|rmi)\s" \
    && block "docker rm/rmi — removes containers/images"
  echo "$cmd" | grep -qE "${SEP}docker\s+network\s+(rm|prune)" \
    && block "docker network rm/prune — removes networks"
  echo "$cmd" | grep -qE "${SEP}docker\s+builder\s+prune" \
    && block "docker builder prune — removes build cache"
  echo "$cmd" | grep -qE "${SEP}docker[-[:space:]]compose\s+(rm|down)(\s|$)" \
    && block "docker compose rm/down — removes containers/networks"

  # ── Kubernetes ────────────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}kubectl\s+delete(\s|$)" \
    && block "kubectl delete — destroys Kubernetes resources"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+apply(\s|$)" \
    && block "kubectl apply — modifies cluster state"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+(patch|edit|replace|set)(\s|$)" \
    && block "kubectl mutating operation — modifies cluster resources"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+scale(\s|$)" \
    && block "kubectl scale — changes replica count (can scale to 0)"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+(drain|cordon|uncordon|taint)(\s|$)" \
    && block "kubectl node operation — affects workload scheduling"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+rollout\s+(undo|restart)(\s|$)" \
    && block "kubectl rollout — changes deployment state"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+exec(\s|$)" \
    && block "kubectl exec — runs command inside pod"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+create(\s|$)" \
    && block "kubectl create — creates cluster resources"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+label(\s|$)" \
    && block "kubectl label — modifies resource metadata"

  # ── Terraform / OpenTofu ──────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+apply(\s|$)" \
    && block "terraform apply — modifies infrastructure"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+destroy(\s|$)" \
    && block "terraform destroy — destroys infrastructure"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+import(\s|$)" \
    && block "terraform import — imports resources into state"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+taint(\s|$)" \
    && block "terraform taint — marks resource for recreation"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+state\s+(rm|mv|push|replace-provider)(\s|$)" \
    && block "terraform state mutation — modifies state file"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+force-unlock(\s|$)" \
    && block "terraform force-unlock — overrides state lock"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+workspace\s+delete(\s|$)" \
    && block "terraform workspace delete — removes workspace"

  # ── Helm ──────────────────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}helm\s+(install|upgrade|uninstall|rollback)(\s|$)" \
    && block "helm mutating operation — modifies cluster releases"

  # ── Cloud CLIs ────────────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}aws\s+.+\s+(delete-|remove-|terminate-|stop-|put-|create-|update-|modify-)" \
    && block "AWS CLI mutating operation"
  echo "$cmd" | grep -qE "${SEP}gcloud\s+.+\s+(delete|create|update|deploy|set)(\s|$)" \
    && block "gcloud mutating operation"

  # ── Network: external write requests ──────────────────────
  if echo "$cmd" | grep -qE "${SEP}curl\s.*(-X|--request)\s+(POST|PUT|PATCH|DELETE)"; then
    echo "$cmd" | grep -qvE '(localhost|127\.0\.0\.1|0\.0\.0\.0)' \
      && block "curl with write method to external service"
  fi

  # ── Remote access ─────────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}(ssh|scp)\s+[^-]" \
    && block "ssh/scp — remote server operation requires manual execution"

  # ── Process management ────────────────────────────────────
  echo "$cmd" | grep -qE "${SEP}(kill|killall|pkill)\s" \
    && block "process kill — terminates running processes"

  # ── Credential exposure ───────────────────────────────────
  if echo "$cmd" | grep -qE "${SEP}(cat|less|more|head|tail)\s+.*\.(env|pem|key|secret|credentials|p12|pfx|jks|keystore)"; then
    # Extract sensitive file tokens and filter out public templates (.env.example, .env.local.sample, etc.)
    sensitive_files=$(echo "$cmd" | grep -oE '[^[:space:]]+\.(env|pem|key|secret|credentials|p12|pfx|jks|keystore)([^[:space:]]*)?' 2>/dev/null || true)
    non_whitelist=$(echo "$sensitive_files" | grep -vE '\.(env|env\..+)\.(example|sample|template|dist)$' 2>/dev/null || true)
    [[ -n "$non_whitelist" ]] && block "reading credentials/secrets file — handle manually"
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 2: MCP tool guards
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [[ -n "$tool_name" ]] && [[ "$tool_name" == mcp__* ]]; then

  # Allow local-only MCP plugins (configurable at top of file)
  if echo "$tool_name" | grep -qE "(${MCP_LOCAL_PLUGINS})"; then
    exit 0
  fi

  tool_lower=$(echo "$tool_name" | tr '[:upper:]' '[:lower:]')

  case "$tool_lower" in
    *push*|*force_push*)
      block "MCP push operation '$tool_name'" ;;
    *merge*|*squash*|*rebase*)
      block "MCP merge operation '$tool_name'" ;;
    *delete_file*|*delete_branch*|*delete_repo*|*delete_release*|*delete_ref*)
      block "MCP delete operation '$tool_name'" ;;
    *close_issue*|*close_pull*|*close_pr*)
      block "MCP close operation '$tool_name'" ;;
    *create_pull*|*create_pr*|*open_pull*)
      block "MCP create PR '$tool_name'" ;;
    *create_issue*|*open_issue*)
      block "MCP create issue '$tool_name'" ;;
    *create_release*|*publish_release*)
      block "MCP release operation '$tool_name'" ;;
    *comment*|*review*|*approve*)
      block "MCP comment/review '$tool_name'" ;;
    *create_or_update_file*|*update_file*|*create_file*)
      block "MCP file write '$tool_name'" ;;
    *fork*|*transfer*|*archive*|*rename_repo*)
      block "MCP repo operation '$tool_name'" ;;
    *dispatch*|*trigger*|*workflow_run*)
      block "MCP workflow trigger '$tool_name'" ;;
    *add_label*|*remove_label*|*assign*|*unassign*|*set_*|*update_branch*)
      block "MCP metadata operation '$tool_name'" ;;
  esac
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 3: Read tool — sensitive file guard
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [[ "$tool_name" == "Read" ]]; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
  if [[ -n "$file_path" ]]; then
    if echo "$file_path" | grep -qE '\.(env|pem|key|secret|credentials|p12|pfx|jks|keystore)(\..*)?$'; then
      # Whitelist: public templates without secrets (.env.example, .env.local.sample, etc.)
      if ! echo "$file_path" | grep -qE '\.(env|env\..+)\.(example|sample|template|dist)$'; then
        block "reading sensitive file '$file_path' — handle credentials manually"
      fi
    fi
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# All checks passed — allow
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
exit 0
