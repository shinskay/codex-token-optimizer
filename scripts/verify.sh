#!/usr/bin/env bash
set -u

usage() {
  cat >&2 <<'USAGE'
usage: verify.sh [--label LABEL] -- command [args...]
USAGE
  exit "${1:-2}"
}

(
  label=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --label)
        [ "$#" -ge 2 ] || usage 2
        label="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -h|--help)
        usage 0
        ;;
      *)
        break
        ;;
    esac
  done

  [ "$#" -gt 0 ] || usage 2

  if [ -n "$label" ]; then
    case "$label" in
      *[!A-Za-z0-9._-]*)
        echo "ERROR: label may contain only letters, numbers, dot, underscore, and hyphen" >&2
        exit 2
        ;;
    esac
  else
    label="$(date +%Y%m%d-%H%M%S)-$$"
  fi

  if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    in_git_repo=1
  else
    repo_root="$PWD"
    in_git_repo=0
  fi

  log_dir="$repo_root/.codex"
  if ! mkdir -p "$log_dir"; then
    echo "ERROR: cannot create $log_dir" >&2
    exit 2
  fi

  if [ "$in_git_repo" -eq 1 ]; then
    exclude="$(git -C "$repo_root" rev-parse --git-path info/exclude 2>/dev/null || true)"
    if [ -n "$exclude" ]; then
      case "$exclude" in
        /*) ;;
        *) exclude="$repo_root/$exclude" ;;
      esac
      if mkdir -p "$(dirname -- "$exclude")" 2>/dev/null && touch "$exclude" 2>/dev/null; then
        grep -qxF '/.codex/' "$exclude" 2>/dev/null || printf '/.codex/\n' >>"$exclude"
      else
        echo "WARNING: could not update $exclude; .codex may appear in git status" >&2
      fi
    fi
  fi

  base="$log_dir/verify-$label"
  log="$base.log"
  n=2
  while [ -e "$log" ]; do
    log="$base-$n.log"
    n=$((n + 1))
  done

  "$@" >"$log" 2>&1
  status=$?

  if [ "$status" -eq 0 ]; then
    tail -n 5 "$log" || true
  else
    tail_lines=40
    line_count="$(wc -l <"$log" | tr -d ' ')"
    prefix_lines=$((line_count > tail_lines ? line_count - tail_lines : 0))

    tail -n "$tail_lines" "$log" || true

    if [ "$prefix_lines" -gt 0 ]; then
      if command -v rg >/dev/null 2>&1; then
        head -n "$prefix_lines" "$log" | rg -ni 'error|fail|warn|traceback|assert' | head -n 40 || true
      else
        head -n "$prefix_lines" "$log" | grep -niE 'error|fail|warn|traceback|assert' | head -n 40 || true
      fi
    fi
  fi

  printf 'verify_log=%s\n' "$log"
  printf 'verify_exit=%s\n' "$status"
  exit "$status"
)
