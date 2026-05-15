#!/bin/bash
# PreToolUse hook: blocks destructive and repository-altering operations.

set +e

MCP_LOCAL_PLUGINS="code[-_]review[-_]graph|context7"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // .toolName // .tool // .name // empty' 2>/dev/null || true)
cmd=$(
  echo "$input" | jq -r '
    .tool_input.command //
    .tool_input.cmd //
    .tool_input.arguments.command //
    .arguments.command //
    .input.command //
    .command //
    .cmd //
    empty
  ' 2>/dev/null || true
)

block() {
  echo "BLOCKED: $1" >&2
  echo "Inform the user what you intended to do and ask them to run it manually." >&2
  exit 2
}

SEP='(^|[;&|]+[[:space:]]*)'
GIT_BIN='(rtk[[:space:]]+)?git'
GIT_GLOBAL_OPTS='([[:space:]]+(-C|-c)[[:space:]]+[^[:space:];&|]+|[[:space:]]+(--git-dir|--work-tree|--namespace|--exec-path)(=|[[:space:]]+)[^[:space:];&|]+|[[:space:]]+--(bare|no-pager|paginate|no-replace-objects|literal-pathspecs|glob-pathspecs|noglob-pathspecs|icase-pathspecs|no-optional-locks))*'

git_cmd_re() {
  printf '%s%s%s[[:space:]]+%s([[:space:]]|$)' "$SEP" "$GIT_BIN" "$GIT_GLOBAL_OPTS" "$1"
}

if [[ -n "$cmd" ]]; then
  # Regular `git push` is allowed; only force pushes (rewrite remote history) are blocked.
  if echo "$cmd" | grep -qE "$(git_cmd_re 'push')"; then
    echo "$cmd" | grep -qE '(--force(-with-lease|-if-includes)?([[:space:]]|=|$)|[[:space:]]-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$))' \
      && block "git push --force/-f - rewrites remote history"
  fi

  echo "$cmd" | grep -qE "$(git_cmd_re 'reset[[:space:]]+--hard')" \
    && block "git reset --hard - discards all uncommitted changes"
  echo "$cmd" | grep -qE "$(git_cmd_re 'checkout[[:space:]]+--')" \
    && block "git checkout -- - discards working tree changes"
  echo "$cmd" | grep -qE "$(git_cmd_re 'restore[[:space:]]+[^-]*(\.|\*)')" \
    && ! echo "$cmd" | grep -qE "$(git_cmd_re 'restore[[:space:]]+--staged')" \
    && block "git restore - bulk discards changes"
  echo "$cmd" | grep -qE "$(git_cmd_re 'clean[[:space:]]+-[a-zA-Z]*f')" \
    && block "git clean -f - removes untracked files permanently"
  echo "$cmd" | grep -qE "$(git_cmd_re 'branch[[:space:]]+.*-D')" \
    && block "git branch -D - force-deletes branch without merge check"
  echo "$cmd" | grep -qE "$(git_cmd_re 'stash[[:space:]]+(drop|clear)')" \
    && block "git stash drop/clear - permanently discards stashed work"

  echo "$cmd" | grep -qE "$(git_cmd_re 'commit[[:space:]].*--amend')" \
    && block "git commit --amend - rewrites the last commit"

  echo "$cmd" | grep -qE "$(git_cmd_re 'remote[[:space:]]+(add|remove|rm|set-url|rename)')" \
    && block "git remote modification - alters remote configuration"
  echo "$cmd" | grep -qE "$(git_cmd_re 'tag[[:space:]]+(-d|--delete)')" \
    && block "git tag delete - removes tags"
  echo "$cmd" | grep -qE "$(git_cmd_re 'fetch[[:space:]].*--prune')" \
    && block "git fetch --prune - deletes remote-tracking branches"
  echo "$cmd" | grep -qE "$(git_cmd_re 'commit[[:space:]].*(-n|--no-verify)')" \
    && block "git commit --no-verify - bypasses pre-commit hooks"

  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+merge(\s|$)" \
    && block "gh pr merge - merges a pull request"
  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+close(\s|$)" \
    && block "gh pr close - closes a pull request"
  # `gh pr review --comment` is a plain comment-only review and is allowed;
  # only state-changing reviews (approve/request-changes) must be manual.
  if echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+review(\s|$)"; then
    echo "$cmd" | grep -qE '(\s)(-a|-r|--approve|--request-changes)(\s|=|$)' \
      && block "gh pr review --approve/--request-changes - must be manual"
  fi
  echo "$cmd" | grep -qE "${SEP}gh\s+pr\s+(edit|reopen)(\s|$)" \
    && block "gh pr edit/reopen - modifies a pull request"

  # `gh issue create`, `gh pr create`, and plain `comment` ops are allowed;
  # other mutating ops on existing items remain blocked.
  echo "$cmd" | grep -qE "${SEP}gh\s+issue\s+(close|edit|reopen|delete|transfer|pin|unpin)(\s|$)" \
    && block "gh issue write operation - modifies GitHub issues"
  echo "$cmd" | grep -qE "${SEP}gh\s+repo\s+(delete|archive|rename|edit)(\s|$)" \
    && block "gh repo destructive operation"
  echo "$cmd" | grep -qE "${SEP}gh\s+release\s+(create|delete|edit)(\s|$)" \
    && block "gh release modification - affects published releases"
  echo "$cmd" | grep -qE "${SEP}gh\s+(label|variable|secret)\s+(create|set|edit|delete)(\s|$)" \
    && block "gh label/variable/secret modification"

  if echo "$cmd" | grep -qE "${SEP}gh\s+api\s"; then
    if echo "$cmd" | grep -qE '(-X|--method)\s+(POST|PUT|PATCH|DELETE)'; then
      # Allow POST to comment-only endpoints:
      #   repos/{o}/{r}/pulls/{n}/reviews                       - review w/ inline comments
      #   repos/{o}/{r}/pulls/{n}/comments                      - standalone review comment
      #   repos/{o}/{r}/pulls/{n}/comments/{id}/replies         - reply to a review comment
      #   repos/{o}/{r}/issues/{n}/comments                     - issue/PR-level comment
      if echo "$cmd" | grep -qE '(-X|--method)\s+POST' \
         && echo "$cmd" | grep -qE 'repos/[^/[:space:]]+/[^/[:space:]]+/(pulls/[0-9]+/(reviews|comments(/[0-9]+/replies)?)|issues/[0-9]+/comments)([[:space:]"'\'']|$)'; then
        :
      else
        block "gh api with write method - modifies GitHub state"
      fi
    fi
  fi
  echo "$cmd" | grep -qE "${SEP}gh\s+workflow\s+run(\s|$)" \
    && block "gh workflow run - triggers a GitHub Actions workflow"
  echo "$cmd" | grep -qE "${SEP}gh\s+gist\s+(create|edit|delete)(\s|$)" \
    && block "gh gist write operation"

  echo "$cmd" | grep -qE "${SEP}(npm|pnpm|yarn)\s+publish(\s|$)" \
    && block "package publish - publishes to npm registry"
  echo "$cmd" | grep -qE "${SEP}npx\s+-y\s" \
    && block "npx -y - auto-installs remote packages without confirmation"
  echo "$cmd" | grep -qE "${SEP}bunx\s" \
    && block "bunx - auto-installs and runs remote package"

  echo "$cmd" | grep -qE "${SEP}rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+(/|\.\.|~|\\\$HOME|\.git)" \
    && block "rm -rf on sensitive path - potentially irreversible"
  echo "$cmd" | grep -qE "${SEP}rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+\.\s*$" \
    && block "rm -rf . - deletes everything in current directory"
  echo "$cmd" | grep -qE "${SEP}rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+\*" \
    && block "rm -rf * - deletes everything in current scope"

  echo "$cmd" | grep -qE '(^|[;&|]+\s*)>\s*/[^\s]' \
    && ! echo "$cmd" | grep -qE '(/dev/null|/tmp/)' \
    && block "file truncation with > - verify target file"

  echo "$cmd" | grep -qiE "${SEP}dropdb([[:space:]]|$)" \
    && block "database drop operation - destroys data permanently"

  if echo "$cmd" | grep -qE "${SEP}(psql|mysql|mongosh?|redis-cli)\s.*(-c|-e|--eval)\s"; then
    echo "$cmd" | grep -qiE "DROP\s+(DATABASE|TABLE|SCHEMA)" \
      && block "database drop operation - destroys data permanently"
    echo "$cmd" | grep -qiE "TRUNCATE\s+" \
      && block "TRUNCATE - deletes all rows permanently"
    echo "$cmd" | grep -qiE "DELETE\s+FROM\s+\w+\s*$" \
      && block "DELETE without WHERE - deletes all rows"
    echo "$cmd" | grep -qiE "ALTER\s+TABLE\s+.*\bDROP\b" \
      && block "ALTER TABLE DROP - removes columns/constraints"
    block "database CLI with inline command - verify before executing"
  fi

  echo "$cmd" | grep -qE "${SEP}docker\s+(system\s+prune|container\s+rm|image\s+rm|volume\s+rm)" \
    && block "docker destructive operation - removes resources"
  echo "$cmd" | grep -qE "${SEP}docker\s+push(\s|$)" \
    && block "docker push - publishes image to registry"
  echo "$cmd" | grep -qE "${SEP}docker\s+(stop|kill)\s" \
    && block "docker stop/kill - stops running containers"
  echo "$cmd" | grep -qE "${SEP}docker\s+(rm|rmi)\s" \
    && block "docker rm/rmi - removes containers/images"
  echo "$cmd" | grep -qE "${SEP}docker\s+network\s+(rm|prune)" \
    && block "docker network rm/prune - removes networks"
  echo "$cmd" | grep -qE "${SEP}docker\s+builder\s+prune" \
    && block "docker builder prune - removes build cache"
  echo "$cmd" | grep -qE "${SEP}docker[-[:space:]]compose\s+(rm|down)(\s|$)" \
    && block "docker compose rm/down - removes containers/networks"

  echo "$cmd" | grep -qE "${SEP}kubectl\s+delete(\s|$)" \
    && block "kubectl delete - destroys Kubernetes resources"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+apply(\s|$)" \
    && block "kubectl apply - modifies cluster state"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+(patch|edit|replace|set)(\s|$)" \
    && block "kubectl mutating operation - modifies cluster resources"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+scale(\s|$)" \
    && block "kubectl scale - changes replica count"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+(drain|cordon|uncordon|taint)(\s|$)" \
    && block "kubectl node operation - affects workload scheduling"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+rollout\s+(undo|restart)(\s|$)" \
    && block "kubectl rollout - changes deployment state"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+exec(\s|$)" \
    && block "kubectl exec - runs command inside pod"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+create(\s|$)" \
    && block "kubectl create - creates cluster resources"
  echo "$cmd" | grep -qE "${SEP}kubectl\s+label(\s|$)" \
    && block "kubectl label - modifies resource metadata"

  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+apply(\s|$)" \
    && block "terraform apply - modifies infrastructure"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+destroy(\s|$)" \
    && block "terraform destroy - destroys infrastructure"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+import(\s|$)" \
    && block "terraform import - imports resources into state"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+taint(\s|$)" \
    && block "terraform taint - marks resource for recreation"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+state\s+(rm|mv|push|replace-provider)(\s|$)" \
    && block "terraform state mutation - modifies state file"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+force-unlock(\s|$)" \
    && block "terraform force-unlock - overrides state lock"
  echo "$cmd" | grep -qE "${SEP}(terraform|tofu)\s+workspace\s+delete(\s|$)" \
    && block "terraform workspace delete - removes workspace"

  echo "$cmd" | grep -qE "${SEP}helm\s+(install|upgrade|uninstall|rollback)(\s|$)" \
    && block "helm mutating operation - modifies cluster releases"

  echo "$cmd" | grep -qE "${SEP}aws\s+.+\s+(delete-|remove-|terminate-|stop-|put-|create-|update-|modify-)" \
    && block "AWS CLI mutating operation"
  echo "$cmd" | grep -qE "${SEP}gcloud\s+.+\s+(delete|create|update|deploy|set)(\s|$)" \
    && block "gcloud mutating operation"

  if echo "$cmd" | grep -qE "${SEP}curl\s.*(-X|--request)\s+(POST|PUT|PATCH|DELETE)"; then
    echo "$cmd" | grep -qvE '(localhost|127\.0\.0\.1|0\.0\.0\.0)' \
      && block "curl with write method to external service"
  fi

  echo "$cmd" | grep -qE "${SEP}(ssh|scp)\s+[^-]" \
    && block "ssh/scp - remote server operation requires manual execution"
  echo "$cmd" | grep -qE "${SEP}(kill|killall|pkill)\s" \
    && block "process kill - terminates running processes"

  if echo "$cmd" | grep -qE "${SEP}(cat|less|more|head|tail)\s+.*\.(env|pem|key|secret|credentials|p12|pfx|jks|keystore)"; then
    sensitive_files=$(echo "$cmd" | grep -oE '[^[:space:]]+\.(env|pem|key|secret|credentials|p12|pfx|jks|keystore)([^[:space:]]*)?' 2>/dev/null || true)
    non_whitelist=$(echo "$sensitive_files" | grep -vE '\.(env|env\..+)\.(example|sample|template|dist)$' 2>/dev/null || true)
    [[ -n "$non_whitelist" ]] && block "reading credentials/secrets file - handle manually"
  fi
fi

if [[ -n "$tool_name" ]] && [[ "$tool_name" == mcp__* ]]; then
  if echo "$tool_name" | grep -qE "(${MCP_LOCAL_PLUGINS})"; then
    exit 0
  fi

  tool_lower=$(echo "$tool_name" | tr '[:upper:]' '[:lower:]')
  mcp_action="$tool_lower"
  [[ "$mcp_action" == mcp__*__* ]] && mcp_action="${mcp_action##*__}"

  case "$mcp_action" in
    *force_push*) block "MCP force-push operation '$tool_name'" ;;
    *merge*|*squash*|*rebase*) block "MCP merge operation '$tool_name'" ;;
    *delete_file*|*delete_branch*|*delete_repo*|*delete_release*|*delete_ref*) block "MCP delete operation '$tool_name'" ;;
    *close_issue*|*close_pull*|*close_pr*) block "MCP close operation '$tool_name'" ;;
    *create_release*|*publish_release*) block "MCP release operation '$tool_name'" ;;
    *comment*|*review*|*approve*) block "MCP comment/review '$tool_name'" ;;
    *create_or_update_file*|*update_file*|*create_file*) block "MCP file write '$tool_name'" ;;
    *fork*|*transfer*|*archive*|*rename_repo*) block "MCP repo operation '$tool_name'" ;;
    *dispatch*|*trigger*|*workflow_run*) block "MCP workflow trigger '$tool_name'" ;;
    *add_label*|*remove_label*|*assign*|*set_*|*update_branch*) block "MCP metadata operation '$tool_name'" ;;
  esac
fi

if [[ "$tool_name" == "Read" || "$tool_name" == "read" ]]; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // .file_path // .path // empty' 2>/dev/null || true)
  if [[ -n "$file_path" ]]; then
    if echo "$file_path" | grep -qE '\.(env|pem|key|secret|credentials|p12|pfx|jks|keystore)(\..*)?$'; then
      if ! echo "$file_path" | grep -qE '\.(env|env\..+)\.(example|sample|template|dist)$'; then
        block "reading sensitive file '$file_path' - handle credentials manually"
      fi
    fi
  fi
fi

exit 0
