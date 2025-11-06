#!/usr/bin/env bash
# =============================================================================
# strategies/conflict/union.sh - Union merge conflict resolution strategy
# =============================================================================
# Automatically resolves conflicts by concatenating BOTH sides.
#
# WARNING: This is EXPERIMENTAL and may produce broken code!
#   - No semantic understanding of code structure
#   - Creates duplicates (methods, variables, imports)
#   - Works well for: CHANGELOG, independent config additions
#   - Breaks for: code conflicts, configuration values
# =============================================================================

# shellcheck source=.github/scripts/lib/core.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/core.sh"
# shellcheck source=.github/scripts/lib/git-helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/git-helpers.sh"

# Resolve conflicts using union merge strategy
# Args: $1 = context (e.g., "PR #42" or "base sync")
# Sets: HAD_CONFLICTS=true in env if conflicts found
# Returns: 0 (always succeeds, caller validates result)
resolve_conflicts_union() {
  local context="${1:-unknown}"
  local conflicts

  conflicts="$(get_conflicted_files)"

  if [[ -z "$conflicts" ]]; then
    log_debug "No conflicts detected for $context"
    return 0
  fi

  log_warn "Resolving conflicts for $context using union merge"
  export_env "HAD_CONFLICTS" "true"

  # Log conflict header
  require_env CONFLICT_LOG_FILE
  {
    echo ""
    echo "## 🔀 Union Merge: $context"
    echo ""
    echo "### Files resolved:"
  } >> "$CONFLICT_LOG_FILE"

  # Process each conflicted file
  local file
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    log_debug "Union merging: $file"
    echo "- \`$file\`" >> "$CONFLICT_LOG_FILE"

    # Annotate file in GitHub UI
    log_warn "file=$file::Conflict auto-resolved via union merge"

    if git_stage_exists 1 "$file"; then
      # Three-way merge available: concatenate ours + theirs
      {
        git_show_stage 2 "$file"
        git_show_stage 3 "$file"
      } > "$file"

      # Save audit trail with conflict markers
      {
        echo "<<<<<<< OURS"
        git_show_stage 2 "$file"
        echo "======="
        git_show_stage 3 "$file"
        echo ">>>>>>> THEIRS"
      } > "${file}.union-merge"
    else
      # No merge base: fallback to theirs
      log_debug "No merge base for $file, using theirs"
      checkout_stage theirs "$file"
    fi

    stage_file "$file"

    # Log preview
    {
      echo "  <details><summary>Preview (first 20 lines)</summary>"
      echo ""
      echo '  ```'
      head -n 20 "$file" 2>/dev/null || echo "  (binary/unreadable)"
      echo '  ```'
      echo "  </details>"
      echo ""
    } >> "$CONFLICT_LOG_FILE"
  done <<< "$conflicts"

  local count
  count="$(echo "$conflicts" | wc -l)"
  log_info "Union merged $count file(s) for $context"
  return 0
}
