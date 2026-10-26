# git-commands plugin loader for zsh.
#
# Sourcing this file wires the repo into an interactive shell:
#   - adds this repo's bin/ to $path so the git-* subcommands resolve as
#     `git <name>` (and as bare `git-<name>` executables),
#   - adds this repo's completions/ to the front of $fpath so zsh can find
#     the _git-commands completion definitions,
#   - defines a small set of aliases that act as a single "stop" (entry
#     point) for the repo's commands and helpers.
#
# It follows the Zsh Plugin Standard for resolving its own location, so it
# works whether sourced directly, loaded by a plugin manager, or symlinked:
#   https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html#zero-handling

0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

local git_commands_bin="${0:h}/bin"
local git_commands_completions="${0:h}/completions"

# Only add each directory if it is not already present, so re-sourcing the
# file does not grow $path / $fpath.
if [[ -z "${path[(r)${git_commands_bin}]}" ]]; then
	path+=( "${git_commands_bin}" )
fi

if [[ -z "${fpath[(r)${git_commands_completions}]}" ]]; then
	fpath=( "${git_commands_completions}" ${fpath} )
fi

# Register this repo's subcommands with zsh's git completion.
#
# zsh's own `_git` reads the `user-commands` list style and merges those
# entries into the `git <TAB>` command list. We set the style HERE, at
# plugin-load time, rather than from a `#compdef git` completion file:
# a `#compdef git` file would *replace* `_git` entirely (so `git <TAB>`
# would show only our commands, or nothing), whereas setting the style
# lets the real `_git` run and augment its list with ours.
#
# The ':completion:*:*:git:*' pattern matches the $curcontext that `_git`
# uses when it reads the style while completing a git command name.
zstyle ':completion:*:*:git:*' user-commands \
	browse:'Open a remote web page in a browser' \
	edit:'Clone/update a repo with git-get, then open it in your editor' \
	find:'fzf-pick a repo under the projects dir and print its path (for cd "$(git find)")' \
	get:'Clone a repo into a URL-shaped path tree, or update it in place' \
	goto-root:'Print the repository top-level directory (for cd "$(git goto-root)")' \
	jira:'Work with the branch'\''s Jira issue (e.g. git jira open) via acli' \
	mr:'Synonym for git pr (show the branch'\''s merge/pull request)' \
	pr:'Show the branch'\''s pull/merge request via gh or glab (url/open/view)' \
	reset-hard:'Reset to a ref and clean build artifacts, stashing changes by default' \
	whoami:'Show the git author/committer identity that would be used here' \
	work:'Drive a unit of work: start | commit | end (see git work help)' \
	work-start:'Pick a worktree/branch (or make one) with fzf, then open it in your editor' \
	work-commit:'Stage (add -A, unstage what you drop) and hand the commit to your AI CLI tool' \
	work-end:'Run work commit, then have your AI CLI tool create/update the branch'\''s MR' \
	worktree-checkout-branches:'Check out a worktree for every non-default branch' \
	worktree-cleanup-branches:'Remove worktrees whose upstream branch is gone (interactive)' \
	worktree-prune-branches:'Prune gone-upstream worktrees non-interactively (assumes yes)'

# Jump to the repo root using this repo's own git-goto-root (not
# `git rev-parse`), so the alias and the command agree on what "root"
# means (e.g. inside a linked worktree). Prints the directory it lands in.
alias gitroot='cd "$(git goto-root)" && echo "$PWD"'
# Synonym, for muscle memory that reaches for a `git-`-prefixed name.
alias git-cdroot='cd "$(git goto-root)" && echo "$PWD"'

# Pick a repository under the projects directory with `git find`'s fzf menu
# and cd to it. git-find prints the chosen toplevel on its final line and
# exits non-zero (printing nothing on stdout) when you cancel or nothing is
# selected, so we capture the path, and only cd when one actually came back:
# the `&& [ -n "$d" ]` guard means a cancelled pick leaves you where you are.
# Defined as a function (not a simple alias) so the capture + guard logic
# can live in one reusable gesture. Guarded like the aliases below so
# sourcing never clobbers a `gfind` you already defined.
(( ${+functions[gfind]} )) || (( ${+aliases[gfind]} )) || gfind() {
	local d
	d="$(git find "$@")" && [ -n "$d" ] && cd "$d" && echo "$PWD"
}

# Short aliases for the common commands. Each is guarded so sourcing this
# file never clobbers an alias you already defined: `(( ${+aliases[name]} ))`
# is true when an alias of that name already exists, so we only define ours
# when there is none.
(( ${+aliases[gget]} ))    || alias gget='git get'
(( ${+aliases[gedit]} ))   || alias gedit='git edit'
(( ${+aliases[gwork]} ))   || alias gwork='git work'
(( ${+aliases[gws]} ))     || alias gws='git work start'
(( ${+aliases[gwc]} ))     || alias gwc='git work commit'
(( ${+aliases[gwe]} ))     || alias gwe='git work end'
(( ${+aliases[gbrowse]} )) || alias gbrowse='git browse'
(( ${+aliases[gwhoami]} )) || alias gwhoami='git whoami'
(( ${+aliases[gjira]} ))   || alias gjira='git jira'
(( ${+aliases[gpr]} ))     || alias gpr='git pr'
(( ${+aliases[gmr]} ))     || alias gmr='git mr'
(( ${+aliases[greset]} ))  || alias greset='git reset-hard'
