#!/usr/bin/env bash
#
# Bash completion for the git-commands repo.
#
# Source this file from your ~/.bashrc, or drop it into a bash-completion
# directory (e.g. /etc/bash_completion.d/ or
# ~/.local/share/bash-completion/completions/). It completes the repo's
# commands when invoked in their standalone `git-<name>` form.

# --- Helper functions ---

# List remote names, one per line.
__git_commands_remote_names() {
  git remote 2>/dev/null
}

# List local branch names, one per line.
__git_commands_branch_names() {
  git branch --format='%(refname:short)' 2>/dev/null
}

# Fill COMPREPLY from a wordlist, filtered by the current word.
__git_commands_complete_words() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -W "$1" -- "$cur"))
}

# --- Individual command completions ---

# git browse [remote] -- one optional remote name.
_git_browse() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$(__git_commands_remote_names)" -- "$cur"))
  fi
}

# git edit [--no-update|-n] [--fetch-only|-F] [--worktree|-w <branch>] [<repo>]
_git_edit() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "-w" || "$prev" == "--worktree" ]]; then
    COMPREPLY=($(compgen -W "$(__git_commands_branch_names)" -- "$cur"))
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "-n --no-update -F --fetch-only -w --worktree"
  else
    COMPREPLY=() # repo URL is free text
  fi
}

# git get [--fetch-only|-F] [--worktree|-w <branch>] [<repo>]
_git_get() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "-w" || "$prev" == "--worktree" ]]; then
    COMPREPLY=($(compgen -W "$(__git_commands_branch_names)" -- "$cur"))
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "-F --fetch-only -w --worktree"
  else
    COMPREPLY=() # repo URL is free text
  fi
}

# git find [-d|--dir <dir>] [--help|-h]
_git_find() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "-d" || "$prev" == "--dir" ]]; then
    COMPREPLY=($(compgen -d -- "$cur")) # a directory path
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "-d --dir -h --help"
  else
    COMPREPLY=() # no positional arguments
  fi
}

# git goto-root [--help|-h] -- help flags only.
_git_goto_root() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  __git_commands_complete_words "-h --help"
}

# git jira <subcommand> [branch] -- subcommand, then an optional branch.
_git_jira() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 1 ]]; then
    __git_commands_complete_words "open id help"
  else
    # After the subcommand, the single optional argument is a branch name.
    COMPREPLY=($(compgen -W "$(__git_commands_branch_names)" -- "$cur"))
  fi
}

# git pr [url|open|view] [remote] -- subcommand, then an optional remote.
_git_pr() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 1 ]]; then
    # First word may be a subcommand or (defaulting to url) a remote name.
    __git_commands_complete_words "url open view help $(__git_commands_remote_names)"
  else
    COMPREPLY=($(compgen -W "$(__git_commands_remote_names)" -- "$cur"))
  fi
}

# git mr -- synonym for git pr; same completion.
_git_mr() {
  _git_pr
}

# git reset-hard [--no-stash] [--no-stash-tracked] [--no-stash-untracked]
#                [-r|--ref <ref>] [-n|--dry-run] [-y|--yes]
_git_reset_hard() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "-r" || "$prev" == "--ref" ]]; then
    # A ref/commit: offer local branches (free text is also fine).
    COMPREPLY=($(compgen -W "$(__git_commands_branch_names)" -- "$cur"))
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "--no-stash --no-stash-tracked --no-stash-untracked -r --ref -n --dry-run -y --yes -h --help"
  else
    COMPREPLY=() # no positional arguments
  fi
}

# git whoami -- no arguments.
_git_whoami() {
  COMPREPLY=()
}

# git work <subcommand> ... -- dispatcher. Complete the subcommand in the
# first position; after that, hand off to the matching work-<sub> completer
# so `git work commit <TAB>` offers git-work-commit's own flags.
_git_work() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 1 ]]; then
    __git_commands_complete_words "start commit end help"
    return
  fi
  case "${COMP_WORDS[1]}" in
    start)  _git_work_start_body ;;
    commit) _git_work_commit_body ;;
    end)    _git_work_end_body ;;
    *)      COMPREPLY=() ;;
  esac
}

# git work start / git-work-start
# [-a|--max-age <duration>] [-F|--fetch-only] [-d|--dir <dir>]
_git_work_start_body() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "-a" || "$prev" == "--max-age" ]]; then
    COMPREPLY=() # free-text duration, e.g. "1 week"
  elif [[ "$prev" == "-d" || "$prev" == "--dir" ]]; then
    COMPREPLY=($(compgen -d -- "$cur")) # a directory path
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "-a --max-age -F --fetch-only -d --dir -h --help"
  else
    COMPREPLY=() # no positional arguments
  fi
}
_git_work_start() { _git_work_start_body; }

# git work commit / git-work-commit
# [--ci-skip|--ci] [--no-push] [--prompt <text>]
_git_work_commit_body() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "--prompt" ]]; then
    COMPREPLY=() # free-text commit prompt
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "--ci-skip --ci --no-push --prompt -h --help"
  else
    COMPREPLY=() # no positional arguments
  fi
}
_git_work_commit() { _git_work_commit_body; }

# git work end / git-work-end
# [--ci-skip|--ci] [--commit-prompt <text>] [--mr-prompt <text>]
_git_work_end_body() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "--commit-prompt" || "$prev" == "--mr-prompt" ]]; then
    COMPREPLY=() # free-text prompt
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "--ci-skip --ci --commit-prompt --mr-prompt -h --help"
  else
    COMPREPLY=() # no positional arguments
  fi
}
_git_work_end() { _git_work_end_body; }

# git worktree-checkout-branches [-a|--max-age <duration>] [remote]
_git_worktree_checkout_branches() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  if [[ "$prev" == "-a" || "$prev" == "--max-age" ]]; then
    COMPREPLY=() # free-text duration, e.g. "3 months"
  elif [[ "$cur" == -* ]]; then
    __git_commands_complete_words "-a --max-age -h --help"
  else
    COMPREPLY=($(compgen -W "$(__git_commands_remote_names)" -- "$cur"))
  fi
}

# git worktree-cleanup-branches [-y|--yes|-f|--force] [-n|--dry-run] [--no-fetch] [remote]
_git_worktree_cleanup_branches() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ "$cur" == -* ]]; then
    __git_commands_complete_words "-y --yes -f --force -n --dry-run --no-fetch -h --help"
  else
    COMPREPLY=($(compgen -W "$(__git_commands_remote_names)" -- "$cur"))
  fi
}

# git worktree-prune-branches [-f|--force] [-n|--dry-run] [--no-fetch] [remote]
_git_worktree_prune_branches() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ "$cur" == -* ]]; then
    __git_commands_complete_words "-f --force -n --dry-run --no-fetch -h --help"
  else
    COMPREPLY=($(compgen -W "$(__git_commands_remote_names)" -- "$cur"))
  fi
}

# --- Register completions ---
# Map each standalone command name (git-foo-bar) to its completion
# function (_git_foo_bar) and wire it up when that function exists.

_git_commands_list=(
  git-browse
  git-edit
  git-find
  git-get
  git-goto-root
  git-jira
  git-mr
  git-pr
  git-reset-hard
  git-whoami
  git-work
  git-work-start
  git-work-commit
  git-work-end
  git-worktree-checkout-branches
  git-worktree-cleanup-branches
  git-worktree-prune-branches
)

for _cmd in "${_git_commands_list[@]}"; do
  _func="${_cmd//git-/git_}"
  _func="_${_func//-/_}"
  if declare -f "$_func" >/dev/null 2>&1; then
    complete -F "$_func" "$_cmd"
  fi
done
unset _cmd _func _git_commands_list
