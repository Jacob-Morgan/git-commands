<div align="center">

<img src="logo.svg" alt="git-commands" width="320" />

# git-commands

**A small collection of `git` subcommands for cloning into a tidy tree, opening repos in your editor, and managing per-branch worktrees**

![POSIX sh](https://img.shields.io/badge/shell-POSIX%20sh-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![zsh plugin](https://img.shields.io/badge/zsh-plugin-1A1A1A?style=flat-square&logo=zsh&logoColor=white)
![Completions](https://img.shields.io/badge/completions-bash%20%26%20zsh-0A7EA4?style=flat-square)

[Overview](#overview) • [Dependencies](#dependencies) • [Features](#features) • [Project Structure](#project-structure) • [Install](#install) • [Commands](#commands) • [Aliases](#aliases) • [Configuration](#configuration) • [Completions](#completions)


</div>

---

## Overview

`git-commands` is a set of standalone `git-*` scripts that drop onto your `PATH` and become first-class git subcommands. Put the `bin/` directory on `PATH` and `git browse`, `git get`, `git edit`, and the rest all work as if git shipped them.

The scripts are plain POSIX `sh` with no runtime dependencies beyond `git` and the usual core utilities (`sed`, `awk`, `grep`). A zsh plugin loader wires everything up in one step, and bash and zsh completions are included.

Two ideas tie the collection together:

- **A URL-shaped tree.** `git get <url>` clones into `<projects-dir>/<host>/<path>`, so every repo you pull lands in a predictable place that mirrors its remote.
- **Per-branch worktrees.** The `worktree-*` commands check out a separate working directory for each branch under `.worktree-branches/`, then help you clean them up once their upstream branch is merged and deleted.

## Dependencies

The suite is deliberately light on dependencies. Only the first row is required for the collection to work at all; everything else is needed solely by the specific command that uses it, so you only have to install a tool if you actually use that command.

| Dependency | Required by | Notes |
|---|---|---|
| `git` + POSIX `sh`, `sed`, `awk`, `grep` | **Everything** | The scripts are plain POSIX `sh` and shell out only to `git` and these standard core utilities. Present on any Unix-like system out of the box. |
| `date` (GNU **or** BSD/macOS) | `git work start`, `git worktree-checkout-branches` | Used to compute the "recently changed" / stale-branch cutoff. Both `date` dialects are handled, so no install is needed on Linux or macOS. |
| [`fzf`](https://github.com/junegunn/fzf) | `git work start`, `git find` | **Required by these two commands** for their interactive menus; each fails with an install hint if it's missing. Not needed by any other command. |
| [`fd`](https://github.com/sharkdp/fd) | `git work start`, `git find` (optional) | Speeds up the repository browse on large trees (parallel walk). Optional — both commands fall back to `find` automatically when `fd` isn't on `$PATH`. |
| An editor | `git edit`, `git work start` | Resolved from `$VISUAL` / `get.visual` / `$EDITOR` / `core.editor` (see [Configuration](#git-edit--which-editor-opens)). |
| A browser launcher | `git browse` | Uses `git web--browse`, honoring `$BROWSER` (default `open` on macOS). |
| [`gh`](https://cli.github.com) **or** [`glab`](https://gitlab.com/gitlab-org/cli) | `git pr` / `git mr` | Whichever matches the remote's forge (GitHub → `gh`, GitLab → `glab`); must be installed and authenticated. |
| [`acli`](https://developer.atlassian.com/cloud/acli/) (Atlassian CLI) | `git jira open` | Needed only to open the issue; `git jira id` just prints the id and needs nothing. |
| An AI CLI tool | `git work commit`, `git work end` | A configurable command that writes the commit / creates the MR (see [Configuration](#git-work-commit--git-work-end--ai-cli-tool)). |
| `zsh` or `bash` | Shell integration (optional) | For the zsh plugin loader / aliases and the bash completions. The `git-*` scripts themselves run under any POSIX shell. |

## Features

- **URL-mirroring clones** — `git get` maps a remote URL onto `<host>/<path>` on disk for a consistent, forge-agnostic layout
- **Work lifecycle** — `git work <subcommand>` drives a unit of work from first checkout to merge request: `start` (the fzf picker below), `commit` (stage, then hand the commit to your AI CLI tool and push), and `end` (commit, then have the AI tool create/update the branch's MR)
- **Daily-driver picker** — `git work start` lists your worktrees, recent branches, and a "new branch" option in an fzf menu (browsing `get.projectsDir` first when you're not in a repo), then checks out and opens whatever you pick
- **Clone-and-open** — `git edit` forwards to `git get`, then opens the resulting directory (or worktree) in your editor
- **In-place refresh** — run `git get` / `git edit` with no argument to fetch/rebase the repo you're standing in, stashing and restoring local changes around the update
- **Per-branch worktrees** — `git worktree-checkout-branches` creates a worktree for every non-default branch, skipping stale ones (no commit in the last 3 months by default, `--max-age` to tune)
- **Worktree cleanup** — `git worktree-cleanup-branches` (interactive) and `git worktree-prune-branches` (non-interactive) remove worktrees whose upstream branch is gone
- **Browser launcher** — `git browse` normalizes any remote URL (SSH, `ssh://`, HTTPS) into a web URL and opens it
- **Branch's PR/MR** — `git pr` (synonym `git mr`) detects GitHub vs GitLab from the remote and drives `gh` / `glab` to print, open, or show the pull/merge request for the current branch
- **Pristine reset** — `git reset-hard` hard-resets to a ref and `git clean -fdx`s away every untracked and ignored artifact, stashing your tracked and untracked changes first (on by default, each toggleable) and re-applying them after
- **Jira from the branch name** — `git jira open` derives the issue id from the branch prefix and opens it via the Atlassian CLI (`acli`); the id pattern is configurable
- **Identity check** — `git whoami` shows the author/committer identity a commit would use here, with OS-level fallbacks
- **Repo finder** — `git find` fzf-picks a repository under the projects directory and prints its path for `cd "$(git find)"` (the `gfind` alias does the `cd` for you); it shares the not-in-a-repo browse that powers `git work start`
- **Root jumper** — `git goto-root` prints the working-tree top level for `cd "$(git goto-root)"`
- **Built-in help** — every command supports `--help` / `-h`, printed from its own header comment
- **Shell integration** — a zsh plugin loader plus bash and zsh completions

## Project Structure

```
git-commands/
├── bin/                                 # the git-* subcommands (put this on $PATH)
│   ├── git-browse                       # open a remote's web page in a browser
│   ├── git-get                          # clone into a URL-shaped tree, or update in place
│   ├── git-edit                         # git get, then open the result in your editor
│   ├── git-find                         # fzf-pick a repo under the projects dir, print its path
│   ├── git-goto-root                    # print the repository top-level directory
│   ├── git-jira                         # open / show the branch's Jira issue (acli)
│   ├── git-pr                           # show the branch's pull/merge request (gh / glab)
│   ├── git-mr                           # synonym for git-pr
│   ├── git-reset-hard                   # reset to a ref + clean artifacts, stashing changes
│   ├── git-whoami                       # show the git identity used here
│   ├── git-work                         # dispatcher: git work start | commit | end
│   ├── git-work-start                   # fzf-pick a worktree/branch (or make one) and open it
│   ├── git-work-commit                  # stage, hand the commit to your AI CLI tool, push
│   ├── git-work-end                     # commit, then have the AI CLI tool create/update the MR
│   ├── git-worktree-checkout-branches   # a worktree per non-default branch
│   ├── git-worktree-cleanup-branches    # remove worktrees whose upstream is gone (interactive)
│   └── git-worktree-prune-branches      # same, non-interactive (assumes yes)
├── completions/
│   └── git-commands.bash                # bash completion for the git-<name> forms
├── git-commands.plugin.zsh              # zsh plugin loader (PATH, fpath, aliases, git <TAB> descriptions)
└── logo.svg
```

## Install

### Option A — zsh plugin (recommended for zsh users)

Source the plugin from your `~/.zshrc`. It adds `bin/` to `$PATH`, adds `completions/` to `$fpath`, registers the `git <TAB>` subcommand descriptions, and defines a few convenience aliases:

```zsh
source /path/to/git-commands/git-commands.plugin.zsh
```

Source it **before** the completion system initializes so the `git <TAB>` descriptions take effect — under Oh My Zsh that means above `source $ZSH/oh-my-zsh.sh`. See [Completions](#completions) for details.

It also works with plugin managers that source a plugin file, and follows the Zsh Plugin Standard for resolving its own location (so a managed or symlinked install finds its `bin/` and `completions/` correctly). Re-sourcing is safe — it will not duplicate `$PATH` / `$fpath` entries or clobber aliases you already defined.

### Option B — just put `bin/` on your PATH

The scripts are self-contained, so this is all git needs to resolve them as subcommands:

```sh
export PATH="/path/to/git-commands/bin:$PATH"
```

With `bin/` on `PATH`, both forms work: `git get ...` (as a subcommand) and `git-get ...` (the bare executable).

Make sure the scripts are executable:

```sh
chmod +x /path/to/git-commands/bin/git-*
```

## Commands

Every command prints its own documentation with `--help` / `-h`.

### `git get` — clone into a URL-shaped tree, or update in place

```sh
git get [--fetch-only|-F] [--worktree|-w <name>] [<repo>]
```

Clones a remote into `<projects-dir>/<host>/<path>` (trailing `.git` removed), so a repo at `https://github.com/acme/widget.git` lands at `<projects-dir>/github.com/acme/widget`.

| Invocation | Behaviour |
|---|---|
| `git get <url>`, target missing | Clone the default branch into the computed path |
| `git get <url>`, target is a git repo | Update it (full update by default) |
| `git get <url>`, target exists but isn't a repo | Fail |
| `git get` (no argument), inside a repo | Update the current repo **in place** (at its real toplevel) |
| `git get` (no argument), not in a repo | Fail |

**Update modes** (when the target already exists):

| Flag | Effect |
|---|---|
| *(default)* | Fetch, stash local changes (incl. untracked), pull/rebase onto the default branch, re-apply the stash |
| `--fetch-only` / `-F` | Fetch only; the working tree is left untouched |

**Worktrees** — `--worktree` / `-w <name>` clones/updates the default-branch checkout, then adds a worktree for `<name>` under the repo's worktree root (`.worktree-branches/<name>`, slashes turned to dashes; override with `$GIT_WORKTREE_ROOT`). An existing worktree for the branch is left as-is. May be given at most once.

The final line of output is `📂 <result dir>` — the worktree path when `--worktree` was given, otherwise the main checkout. Sister commands read this line.

### `git edit` — clone/update, then open in your editor

```sh
git edit [--no-update|-n] [--fetch-only|-F] [--worktree|-w <name>] [<repo>]
```

A thin sister to `git get`: it forwards every argument to `git get`, then opens the resulting directory (or worktree) in your editor.

| Invocation | Behaviour |
|---|---|
| `git edit <url>` | `git get <url>`, then open the clone/checkout |
| `git edit -w <name> <url>` | Open the worktree that `git get` reports |
| `git edit` (no argument) | Refresh the current repo in place, then open it |
| `git edit --no-update` / `-n` | Open the current repo **without** refreshing (no fetch/stash/pull/rebase) |

`--no-update` is git-edit's own flag (not a `git get` flag) and may only be used on its own — not with a repo URL or any `git get` option. The editor is resolved before any clone/update work, so a missing editor fails fast. See [Configuration](#configuration) for the editor resolution order.

### `git work` — drive a unit of work (start / commit / end)

```sh
git work <subcommand> [args]
```

`git work` is a dispatcher that routes to a `git work-<name>` sibling command (each also runnable standalone). It requires a subcommand:

| Subcommand | Behaviour |
|---|---|
| `start` | Pick a worktree/branch (or make one) with fzf and open it in your editor — the daily-driver picker |
| `commit` | Stage changes (`git add -A`, then unstage what you drop), hand the commit to your AI CLI tool, then optionally push |
| `end` | Run `commit`, then (once the branch is pushed) have the AI CLI tool create/update the branch's merge request |
| `help` | Show help (also `--help` / `-h`) |

Each subcommand has its own `--help`. The `commit` and `end` subcommands delegate the actual commit and merge-request work to a configurable **AI CLI tool** (see [Configuration](#git-work-commit--git-work-end--ai-cli-tool)).

### `git work start` — pick a worktree/branch (or make one) and open it

```sh
git work start [-a|--max-age <duration>] [-F|--fetch-only] [-d|--dir <projects-dir>]
```

The daily-driver entry point (also runnable as `git work-start`). It answers "what am I working on?" with an fzf menu and lands you in your editor on the right working tree, creating a worktree for the chosen branch when one doesn't already exist.

Inside a repository the menu combines:

- every existing **worktree** (except the one you're standing in), **including the main checkout** that holds the default branch (shown as `🏠 main`), so the default branch is selectable too,
- every other **branch** — local or remote-tracking — whose tip commit is within the max-age window (default **1 week**) and that doesn't already have a worktree, and
- a **`➕ new branch…`** entry.

Each row is tagged with its kind so you can tell at a glance what you're picking (and what will happen when you do):

| Row | Meaning | Selecting it |
|---|---|---|
| `🏠 main <branch> · <path>` | The main checkout, holding the default branch | Opens it in place (after an optional update) |
| `🌳 worktree <branch> · <path>` | A worktree that already exists on disk | Opens it (after an optional update) |
| `🔀 branch <name>` | A **local** branch with no worktree yet | Checks it out as a worktree |
| `☁️ remote <name> · <remote>/<name>` | A branch that lives **only on a remote** | Creates a local tracking branch, then a worktree |
| `➕ new …` | The new-branch action | Prompts for a name and branches off the default |

A branch that exists both locally and on a remote is shown once, as a local `🔀 branch`. The default branch appears only as the `🏠 main` row (not also as a `🔀 branch`), and selecting it opens the main checkout in place rather than spawning a feature worktree for it.

Outside a repository it first browses the git repositories under the projects directory (same resolution as `git get`) with fzf, then runs the in-repo flow on the one you pick. The browse lists only top-level repositories: a `.git` nested inside a dot-directory (a repo's own `.worktree-branches/` or `.worktrees/` root, a cache, a vendored tree, …) is skipped, so worktrees and submodules don't clutter the list.

| Choice | Behaviour |
|---|---|
| Existing **worktree** | Prompt to update it first (fetch, stash, pull/rebase onto the default branch, re-apply — i.e. `git get` in place), then open it |
| Existing **branch** | Check it out as a worktree under the repo's worktree root (via `git get --worktree`), then open it |
| **New branch** | Prompt for a name, create a worktree for a fresh branch off the default branch, then open it |

In every case the worktree is opened with `git edit`, so the `$VISUAL` / `get.visual` / `$EDITOR` / `core.editor` chain applies (see [Configuration](#git-edit--which-editor-opens)). Worktrees are created under the repo's worktree root (`.worktree-branches/`, override with `$GIT_WORKTREE_ROOT`), matching the rest of the suite.

| Option | Effect |
|---|---|
| `-a` / `--max-age <duration>` | Window for "recently changed" branches in the menu (default `1 week`; `0`/`none`/`off` lists every branch). Also `$GIT_WORK_MAX_AGE` |
| `-F` / `--fetch-only` | When updating, fetch only; leave the working tree untouched |
| `-d` / `--dir <projects-dir>` | Root to browse when not in a repo (default: the `git get` projects directory) |

When checking out an existing branch, the main-checkout update is a convenience, not the goal: if it fails (e.g. the default branch has no upstream), `git work start` warns and retries fetch-only so the worktree is still created and opened. **`fzf` is required** for the menus; `git work start` fails with an install hint if it's missing.

The not-in-a-repo repository browse scales to large trees (hundreds or thousands of checkouts). It stops descending at each repo root — so it never walks a repo's working tree (`node_modules`, build output, …) — and uses [`fd`](https://github.com/sharkdp/fd) when it's installed (it walks in parallel and is several times faster than `find` here), falling back to `find` otherwise. The walk is depth-bounded as a safety valve against pathological non-repo trees; override the cap with `$GIT_WORK_MAX_DEPTH` (default `8`, generous enough for forge subgroups; `0`/`none`/`off` disables it).

### `git work commit` — stage, hand the commit to your AI CLI tool, push

```sh
git work commit [--ci-skip|--ci] [--no-push] [--prompt <text>]
```

Collapses the manual "review changes in a UI, stage, swap to an AI tool to commit, swap back to push" loop into one command (also runnable as `git work-commit`). Three phases:

1. **Stage** — `git add -A` stages everything (tracked edits, deletions, and untracked files), then an interactive loop lets you **unstage** anything you don't want in this commit. This mirrors the "stage all, then drop what I don't want" workflow. Nothing is committed until you confirm.
2. **Commit** — the staged change is handed to your [AI CLI tool](#git-work-commit--git-work-end--ai-cli-tool), which performs the actual `git commit` (writing the message itself). The default prompt is `commit all staged changes, ignore untracked files`; override it with `--prompt`.
3. **Push** — you're asked, **per push**, whether this one needs a CI build: push with CI, push skipping CI (`-o ci.skip`), or don't push. A first push on a new branch sets upstream (`-u origin <branch>`).

| Option | Effect |
|---|---|
| `--ci-skip` | Push with `-o ci.skip` without asking (skip CI) |
| `--ci` | Push normally without asking (run CI) |
| `--no-push` | Stage and commit only; never push |
| `--prompt <text>` | Override the commit prompt handed to the AI CLI tool |

With none of `--ci-skip` / `--ci` / `--no-push`, the push step is interactive: `[c] with CI`, `[s] skip CI`, `[n] don't push`. The CI-skip choice exists because whether a given push needs a CI build is a per-push question (e.g. a desktop→laptop transfer push doesn't).

| Exit | Meaning |
|---|---|
| `0` | Committed (and pushed, unless you declined / `--no-push`) |
| `1` | A runtime failure (not in a repo, nothing staged, AI tool missing/failed, commit or push failed) |
| `2` | A usage error (unknown option, missing value) |

### `git work end` — commit, then create/update the branch's merge request

```sh
git work end [--ci-skip|--ci] [--commit-prompt <text>] [--mr-prompt <text>]
```

The close-out of a unit of work (also runnable as `git work-end`). It:

1. runs `git work commit` so the latest changes are staged, committed, and pushed. **If that step fails for any reason** — nothing staged, a bad push, you decline the commit — `end` gives up then and there and never creates a merge request.
2. makes sure the branch is on the remote (a merge request needs a pushed branch). If `commit` left it unpushed, `end` asks once more and pushes, or gives up if you decline.
3. hands the MR prompt to your [AI CLI tool](#git-work-commit--git-work-end--ai-cli-tool), which creates the merge request for the current branch — or, if one already exists, refreshes its description to match everything on the branch. The default prompt is `create a merge request for the current branch, if one already exists ensure the description is accurate for all changes in the branch`; override it with `--mr-prompt`.

| Option | Effect |
|---|---|
| `--ci-skip` | Forwarded to `commit`: push with `-o ci.skip` (skip CI) without asking |
| `--ci` | Forwarded to `commit`: push normally (run CI) without asking |
| `--commit-prompt <text>` | Override the commit prompt (see `git work commit`) |
| `--mr-prompt <text>` | Override the MR prompt handed to the AI CLI tool |

| Exit | Meaning |
|---|---|
| `0` | Committed, pushed, and the MR created/updated |
| `1` | A runtime failure (the commit step failed, the branch wasn't pushed, the AI tool is missing/failed) |
| `2` | A usage error (unknown option, missing value) |

### `git browse` — open a remote's web page

```sh
git browse [remote]
```

Looks up the URL of `remote` (default `origin`), normalizes it into an `https://` web URL — handling SCP-style SSH (`git@host:group/repo.git`), `ssh://` (with or without a port), and plain HTTPS, and stripping userinfo, port, and a trailing `.git` — then opens it with `git web--browse`, honoring `$BROWSER` (default `open`).

### `git find` — pick a repository and print its path

```sh
git find [-d|--dir <projects-dir>] [--help|-h]
```

Browses the git repositories under the projects directory (same resolution as `git get`) with an fzf menu and prints the chosen repository's top-level path on the final line, so you can jump there:

```sh
cd "$(git find)"
```

A command can't change your shell's directory, so it prints the path rather than `cd`-ing itself — the `gfind` shell function (shipped by the zsh plugin) does the `cd` for you, and leaves you where you are if you cancel the picker. This is the same not-in-a-repo repository browse that `git work start` runs before its in-repo menu; both share the one implementation, so discovery behaves identically.

The browse lists only top-level repositories: a `.git` nested inside a dot-directory (a repo's own `.worktree-branches/` or `.worktrees/` root, a cache, a vendored tree, …) is skipped, so worktrees and submodules don't clutter the list. It stops descending at each repo root, so it never walks a repo's working tree (`node_modules`, build output, …), and uses [`fd`](https://github.com/sharkdp/fd) when it's installed (it walks in parallel and is several times faster than `find` here), falling back to `find` otherwise.

| Option | Effect |
|---|---|
| `-d` / `--dir <projects-dir>` | Root to browse (default: the `git get` projects directory — see [Configuration](#git-get--where-clones-land)) |

The walk is depth-bounded as a safety valve against pathological non-repo trees; override the cap with `$GIT_WORK_MAX_DEPTH` (default `8`, generous enough for forge subgroups; `0`/`none`/`off` disables it). **`fzf` is required** for the menu; `git find` fails with an install hint if it's missing.

| Exit | Meaning |
|---|---|
| `0` | A repository was selected (its path is printed on the final line) |
| `1` | A setup error (missing `fzf`, projects dir missing, empty `--dir`/config), or you cancelled / selected nothing |
| `2` | A usage error (unknown option, missing value, unexpected argument) |

### `git goto-root` — print the repository top level

```sh
git goto-root [--help|-h]
```

Prints the working tree's top-level directory on the final line so you can jump there:

```sh
cd "$(git goto-root)"
```

A command can't change its parent shell's directory, so it prints the path rather than `cd`-ing itself. Inside a linked worktree it prints that worktree's root. Fails inside a bare repository (no working tree) or outside a repo.

### `git jira` — open or show the branch's Jira issue

```sh
git jira <subcommand> [branch]
```

Derives a Jira issue id from a branch name and acts on it through the Atlassian CLI (`acli`). The id must start the branch name, or the final path segment of a folder-structured name, so all of these resolve to `IRM-216` / `irm-157`:

```
IRM-216-print-agent-communication-api  ->  IRM-216
feature/IRM-216-print-agent-comms       ->  IRM-216
bugfix/irm-157                           ->  irm-157
```

By default the current branch is used; pass a branch name to any subcommand to override it.

| Subcommand | Behaviour |
|---|---|
| `git jira open [branch]` | Open the issue in a browser: `acli jira workitem view <JIRA-ID> --web` |
| `git jira id [branch]` | Print the extracted Jira id and exit (opens nothing) |
| `git jira help` | Show help (also `--help` / `-h`) |

The id is extracted with a POSIX extended regex anchored to the start of the branch name. See [Configuration](#git-jira--jira-id-pattern) for how to change the pattern (e.g. to require an uppercase project key). `git jira open` requires `acli` on `$PATH`; `git jira id` does not.

### `git pr` — show the branch's pull/merge request

```sh
git pr [url|open|view] [remote]
```

Also available as `git mr` — GitHub calls it a pull request, GitLab a merge request, and this one command covers both. It normalizes the remote URL (default `origin`) the way `git browse` does, inspects the host to decide the forge (a host containing `github` → `gh`, one containing `gitlab` → `glab`), then drives that CLI against the request for the **current branch**. Both CLIs resolve the current branch themselves, so there's no branch argument.

| Subcommand | Behaviour |
|---|---|
| `git pr url` *(default)* | Print the request's URL, or fail if the branch has none |
| `git pr open` | Open the request in a browser (`gh pr view --web` / `glab mr view --web`) |
| `git pr view` | Show the request (title, body, status) in the terminal |
| `git pr help` | Show help (also `--help` / `-h`) |

The subcommand is optional and defaults to `url`, so `git pr` prints the URL and `git pr upstream` prints it for the `upstream` remote.

| Exit | Meaning |
|---|---|
| `0` | A request was found (and printed / opened / shown) |
| `1` | No request for the current branch, or a setup error (missing remote, unrecognized host, missing CLI) |
| `2` | Usage error (unknown subcommand or extra argument) |

The matching forge CLI must be installed and authenticated — `gh` ([cli.github.com](https://cli.github.com)) for GitHub, `glab` ([gitlab.com/gitlab-org/cli](https://gitlab.com/gitlab-org/cli)) for GitLab. Hosts that aren't recognizably GitHub or GitLab are an error; use the forge CLI directly for those.

### `git reset-hard` — reset to a ref and clean the tree

```sh
git reset-hard [--no-stash] [--no-stash-tracked] [--no-stash-untracked] [-r|--ref <ref>] [-n|--dry-run] [-y|--yes]
```

Gets you back to a pristine checkout: resets the index and tracked files to a known commit (`HEAD` by default) and removes **every** untracked and ignored file — build output, `node_modules`, vendored deps, editor cruft, anything `git clean -fdx` sweeps away. By default it keeps a stash of your work so nothing is lost silently. The four phases, in order:

| Phase | Action |
|---|---|
| **Stash** | Save tracked and untracked changes (each dimension toggleable; see below) |
| **Reset** | `git reset --hard <ref>` — index + tracked files |
| **Clean** | `git clean -fdx` — untracked **and** ignored files |
| **Apply** | `git stash apply` the stash from phase 1 (kept, not popped, so it survives even a conflicting apply) |

Both stash dimensions are **on by default**, so a plain `git reset-hard` stashes everything, resets, cleans, then re-applies. Ignored files (the bulk of build artifacts) are never stashed — clearing them is the point — but the clean phase always removes them.

| Option | Effect |
|---|---|
| `--no-stash` | Skip the Stash and Apply phases entirely; just reset and clean (nothing kept) |
| `--no-stash-tracked` | Don't include tracked changes in the stash |
| `--no-stash-untracked` | Don't include untracked files in the stash (they're still removed by the clean phase) |
| `-r` / `--ref <ref>` | Reset to `<ref>` instead of `HEAD` — point it at the upstream tip to match upstream exactly, e.g. `--ref @{upstream}` or `--ref origin/main` |
| `-n` / `--dry-run` | Show what each phase would do; change nothing |
| `-y` / `--yes` | Don't prompt for confirmation before the destructive reset/clean |

Because `reset --hard` + `clean -fdx` is destructive (and ignored files are unrecoverable), it prompts for confirmation unless `-y` / `--yes` or `-n` / `--dry-run` is given. On a conflicting re-apply the stash is preserved (not dropped) so you can recover it by hand, and the command exits non-zero to flag it.

| Exit | Meaning |
|---|---|
| `0` | Success |
| `1` | A runtime failure (not in a repo, a git command failed, or a conflicting stash re-apply) |
| `2` | A usage error (unknown option, missing value) |

### `git whoami` — show the identity used here

```sh
git whoami
```

Prints the author (and committer, when it differs) as `Name <email>`, resolving each field through a fallback chain:

| Field | Fallback order |
|---|---|
| name | `git config user.name` → OS account full name (GECOS) → login name |
| email | `git config user.email` → `$EMAIL` → `login@fqdn` |

Useful for confirming which identity a repo will attribute commits to when juggling work/personal configs. Exported `GIT_AUTHOR_*` / `GIT_COMMITTER_*` variables take precedence over the resolved values.

### `git worktree-checkout-branches` — a worktree per branch

```sh
git worktree-checkout-branches [-a|--max-age <duration>] [remote]
```

For every branch other than the repository's default (resolved from `refs/remotes/<remote>/HEAD`, default remote `origin`), adds a git worktree under `.worktree-branches/` (override with `$GIT_WORKTREE_ROOT`), named after the branch with slashes turned to dashes. Branches that already have a worktree, or whose target path exists, are skipped. When the worktree root lives inside the repo it's added to the repo's `info/exclude` so it stays untracked.

**Stale branches are skipped.** By default a branch whose tip commit is older than **3 months** is left alone — there's no point checking out a branch nobody has touched. Change the window with `-a` / `--max-age <duration>` (or `$GIT_WORKTREE_MAX_AGE`):

| Flag / value | Effect |
|---|---|
| *(default)* | Skip branches with no commit in the last 3 months |
| `-a` / `--max-age <duration>` | Use a custom window, e.g. `6 weeks`, `90 days`, `1 year` |
| `--max-age 0` (or `none` / `off`) | Disable the age filter; check out every branch |

`<duration>` is a `<number> <unit>` pair (the space is optional, and a bare number means days). Units accept common spellings — `years`, `months`, `weeks`, `days`, `hours`, `minutes`, `seconds` (and short forms like `y`, `mo`, `w`, `d`). The cutoff is computed with whichever `date` is installed (GNU or BSD/macOS).

### `git worktree-cleanup-branches` — remove stale worktrees (interactive)

```sh
git worktree-cleanup-branches [-y|--yes|-f|--force] [-n|--dry-run] [--no-fetch] [remote]
```

Scans the worktrees under the worktree root and, for each one whose branch's upstream is reported `[gone]`, removes the worktree and deletes the orphaned local branch. To make `[gone]` trustworthy it runs `git fetch --prune` first (disable with `--no-fetch` or `$GIT_WORKTREE_NO_FETCH`).

Because deleting branches is destructive it **prompts per branch by default**. It also **refuses to remove a worktree with uncommitted changes** (a dirty working tree or index), regardless of prompts, so in-progress work is never silently discarded — pass `-f` / `--force` to override that safety check.

| Flag | Effect |
|---|---|
| `-y` / `--yes` | Delete without prompting (or set `$GIT_WORKTREE_CLEANUP_YES=1`) |
| `-f` / `--force` | Remove even worktrees with uncommitted changes (or set `$GIT_WORKTREE_FORCE=1`) |
| `-n` / `--dry-run` | Report what would be removed, change nothing |
| `--no-fetch` | Skip the prune-fetch; use cached remote-tracking refs |

`-y` and `-f` are independent: `-y` skips the confirmation prompts, `-f` overrides the uncommitted-changes guard. A dirty worktree is kept even with `-y` alone; use `-f` (optionally with `-y`) to remove it.

### `git worktree-prune-branches` — remove stale worktrees (non-interactive)

```sh
git worktree-prune-branches [-n|--dry-run] [--no-fetch] [remote]
```

A thin wrapper around `git worktree-cleanup-branches` that assumes "yes" to every prompt, for scripts, hooks, and CI where there's no terminal to answer. All arguments are forwarded, so `--dry-run`, `--no-fetch`, `--force`, and a remote name still work. Note it only passes `--yes`, not `--force`: a worktree with uncommitted changes is still kept unless you add `--force` (or set `$GIT_WORKTREE_FORCE=1`), so unattended runs won't discard in-progress work by default.

## Aliases

Sourcing the zsh plugin defines these convenience aliases (each guarded so it never clobbers one you already have):

| Alias | Expands to |
|---|---|
| `gget` | `git get` |
| `gedit` | `git edit` |
| `gwork` | `git work` |
| `gws` | `git work start` |
| `gwc` | `git work commit` |
| `gwe` | `git work end` |
| `gbrowse` | `git browse` |
| `gwhoami` | `git whoami` |
| `gjira` | `git jira` |
| `gpr` | `git pr` |
| `gmr` | `git mr` |
| `greset` | `git reset-hard` |
| `gfind` | `cd "$(git find)"` (only when a repo is picked; a cancelled picker leaves you put) |
| `gitroot` | `cd "$(git goto-root)" && echo "$PWD"` |
| `git-cdroot` | `cd "$(git goto-root)" && echo "$PWD"` (synonym) |

## Configuration

All configuration is via git config keys or environment variables; nothing is required to get started.

### `git get` — where clones land

The projects directory (the parent under which `<host>/<path>` is created), highest precedence first:

| Source | Notes |
|---|---|
| `$GIT_GET_PROJECTS_DIR` | Per-invocation environment override |
| `git config get.projectsDir` | Persistent default |
| `~/Projects` | Built-in fallback |

An explicitly **empty** value for either the variable or the config key is treated as an error (the command fails) rather than falling back — an empty projects directory would clone straight into `/`. A leading `~` is expanded.

### `git edit` — which editor opens

Editor resolution, highest precedence first:

| Source | Typical use |
|---|---|
| `$VISUAL` | GUI / full-screen editor |
| `git config get.visual` | Dedicated project opener (e.g. `code`) |
| `$EDITOR` | Terminal editor |
| `git config core.editor` | Git's commit-message editor (last resort) |

The order prefers a visual/project opener over a commit-message editor. If none is set, `git edit` fails rather than guessing.

Example `~/.gitconfig`:

```ini
[get]
    projectsDir = ~/Projects   ; where `git get` clones
    visual = code              ; project opener for `git edit`
[core]
    editor = vim               ; git's commit-message editor (fallback)
```

### `git work start` — recent-branch window

`git work start` resolves its projects directory (for the not-in-a-repo browse) from the same chain as `git get` (`-d`/`--dir`, then `$GIT_GET_PROJECTS_DIR`, then `git config get.projectsDir`, then `~/Projects`). Its one extra knob is the window for "recently changed" branches in the menu:

| Source | Notes |
|---|---|
| `-a` / `--max-age <duration>` | Per-invocation override |
| `$GIT_WORK_MAX_AGE` | Persistent default |
| `1 week` | Built-in fallback |

`<duration>` uses the same grammar as `git worktree-checkout-branches` (`3 days`, `2 weeks`, `90` for 90 days, …); `0`/`none`/`off` disables the filter and lists every branch.

For the not-in-a-repo repository browse, one more knob bounds how deep the search looks (a safety valve; the walk already stops at each repo root):

| Source | Notes |
|---|---|
| `$GIT_WORK_MAX_DEPTH` | Max repo depth below the projects directory (default `8`; `0`/`none`/`off` disables the cap) |

`git work start` prefers [`fd`](https://github.com/sharkdp/fd) for this browse when it's on `$PATH` (faster on large trees) and falls back to `find` otherwise — no configuration needed either way.

### `git work commit` / `git work end` — AI CLI tool

`git work commit` and `git work end` delegate the actual commit and merge-request work to an AI CLI tool of your choice. The command to run is resolved, highest precedence first:

| Source | Notes |
|---|---|
| `$AI_CLI_TOOL` | Per-invocation environment override, e.g. `kiro-cli --v3` |
| `git config work.aiTool` | Persistent default |

There is **no built-in fallback** — there's no sensible guess for "which agent commits my work" — so `commit` and `end` fail with a hint if neither is set. An explicitly empty value for either is an error rather than falling through.

The resolved value may carry its own arguments (e.g. `kiro-cli --v3`); it's run with the prompt appended as a single final argument:

```sh
kiro-cli --v3 "commit all staged changes, ignore untracked files"
```

so your tool receives the prompt as `$1` (or the last positional, after its own flags).

**The tool contract (your responsibility, not enforced).** `git work commit` / `git work end` hand the prompt to the tool as a **synchronous foreground call**: they wait for it to exit, then branch on its exit status — nothing more. No single-shot flag is injected and no particular tool is assumed. For the handoff to do what it promises, the command you configure must satisfy three things:

1. **Single-shot** — run one request from the prompt and then **terminate**. A tool that drops into an interactive REPL will *hang* the command (it blocks until the process exits). Add whatever one-shot flag your tool uses (`--no-interactive`, `-p` / `--print`, a `run` / `agent` subcommand, …) to the configured string.
2. **Agent mode (act, don't just chat)** — the tool must actually **perform** the git commit / create the MR, not merely print a suggested command or a chat reply. A plain chat turn typically answers in text and runs nothing, so it would exit `0` having done nothing — the command would look like it succeeded while no commit was made. Enable your tool's "execute tools" / agent / "trust tools" mode. (`git work commit` warns, but does not fail, if changes are still staged after the tool returns — a safety net for exactly this.)
3. **Prompt shape** — the prompt is passed as the single final positional argument (`tool <your flags> "<prompt>"`). If your tool wants the prompt via a flag or on stdin, point `work.aiTool` at a small wrapper script instead.

**The prompts are configurable too.** Each resolves per-invocation flag → git config → built-in default:

| Prompt | Flag | Git config key | Built-in default |
|---|---|---|---|
| Commit (`git work commit`) | `--prompt` | `work.aiCommitPrompt` | `commit all staged changes, ignore untracked files` |
| MR (`git work end`) | `--mr-prompt` | `work.aiMrPrompt` | `create a merge request for the current branch, if one already exists ensure the description is accurate for all changes in the branch` |

(`git work end` also forwards `--commit-prompt` to the commit step; when it's not given, the commit step resolves `work.aiCommitPrompt` itself.) A configured-but-empty value for either prompt key — like an empty `work.aiTool` — is an error rather than a silent fall-through to the default.

Example `~/.gitconfig`:

```ini
[work]
    aiTool = kiro-cli --v3   ; drives `git work commit` and `git work end`
    ; Optional prompt overrides (defaults are used when unset):
    aiCommitPrompt = commit all staged changes, ignore untracked files
    aiMrPrompt = create a merge request for the current branch, if one already exists ensure the description is accurate for all changes in the branch
```

### Worktree commands

| Variable | Effect |
|---|---|
| `$GIT_WORKTREE_ROOT` | Where worktrees are created (default `.worktree-branches/` in the repo root; honored by `git get`, `git work`, and the `worktree-*` commands) |
| `$GIT_WORKTREE_MAX_AGE` | Default staleness window for `git worktree-checkout-branches` (default `3 months`; `0`/`none`/`off` disables it). The `-a`/`--max-age` flag overrides it per-invocation |
| `$GIT_WORKTREE_CLEANUP_YES` | Set to `1` to make `git worktree-cleanup-branches` skip prompts |
| `$GIT_WORKTREE_NO_FETCH` | Set to skip the prune-fetch in the cleanup/prune commands |

### `git browse`

| Variable | Effect |
|---|---|
| `$BROWSER` | Browser command passed to `git web--browse` (default `open`) |

### `git jira` — Jira id pattern

How the issue id is extracted from the branch name. The value is a POSIX extended regex, anchored to the start of the branch, highest precedence first:

| Source | Notes |
|---|---|
| `$GIT_JIRA_PATTERN` | Per-invocation environment override |
| `git config jira.pattern` | Persistent default |
| `^[A-Za-z][A-Za-z0-9]*-[0-9]+` | Built-in fallback |

The default matches a leading letter, then any letters/digits, a hyphen, and one or more digits (`IRM-216`, `PCPP-505`, `AB12-9`). An explicitly **empty** value for either the variable or the config key is treated as an error (an empty pattern would match everything) rather than falling back.

Example — require a 2–4 letter uppercase project key:

```sh
git config jira.pattern '^[A-Z]{2,4}-[0-9]+'
```

## Completions

### zsh

The plugin loader registers this repo's subcommands with zsh's own git completion by setting the `user-commands` list style, so `git <TAB>` lists them alongside git's built-in commands, each with a one-line description. This augments zsh's `_git` rather than replacing it, so normal git completion keeps working.

Because the style has to be set before the completion system initializes, **source the plugin before `compinit` runs**. Under Oh My Zsh, `compinit` runs inside `source $ZSH/oh-my-zsh.sh`, so source the plugin above that line:

```zsh
source /path/to/git-commands/git-commands.plugin.zsh
source $ZSH/oh-my-zsh.sh
```

On a framework-free setup, source the plugin and then run `compinit`:

```zsh
source /path/to/git-commands/git-commands.plugin.zsh
autoload -Uz compinit && compinit
```

If completions don't show up after editing your `~/.zshrc`, clear the cached dump and start a fresh shell (a stale cache can keep the old state):

```zsh
rm -f ~/.zcompdump*
exec zsh
```

### bash

Source the bash completion from your `~/.bashrc`, or drop it into a bash-completion directory (e.g. `/etc/bash_completion.d/` or `~/.local/share/bash-completion/completions/`):

```bash
source /path/to/git-commands/completions/git-commands.bash
```

It completes the standalone `git-<name>` forms — remote names for `git-browse` and the worktree commands, local branch names after `-w` / `--worktree`, and each command's option flags.
