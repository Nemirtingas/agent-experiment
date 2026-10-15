#!/bin/sh
# install.sh - link or copy the workflow skills into the skill directories of coding agents,
# put the two commands on PATH, and prepare a repository.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
bin=${WORKFLOW_BIN:-$HOME/.local/bin}

usage() {
	cat <<'USAGE'
usage: install.sh install   [--copy] [--project DIR] [--no-bin] [TARGET...]
       install.sh uninstall [--project DIR] [TARGET...]
       install.sh project   DIR [--base BRANCH]
       install.sh list

TARGET (default: agents claude)
  agents     ~/.agents/skills           Codex, OpenCode
  claude     ~/.claude/skills           Claude Code, OpenCode
  opencode   ~/.config/opencode/skills  OpenCode
  <dir>      any directory that an agent scans for <name>/SKILL.md
With --project DIR the targets become DIR/.agents/skills, DIR/.claude/skills and
DIR/.opencode/skills.

install links each skill (or copies it with --copy) and links plan-lifecycle and
resource-lock into ~/.local/bin (WORKFLOW_BIN overrides). uninstall removes what
install created. project copies the AGENTS.md template into a repository, creates
its plan directory and records the base branch.
USAGE
}

die() {
	printf 'install.sh: %s\n' "$*" >&2
	exit 1
}

resolve() {
	if [ -n "$project" ]; then
		case $1 in
		agents) printf '%s/.agents/skills' "$project" ;;
		claude) printf '%s/.claude/skills' "$project" ;;
		opencode) printf '%s/.opencode/skills' "$project" ;;
		*) printf '%s' "$1" ;;
		esac
	else
		case $1 in
		agents) printf '%s/.agents/skills' "$HOME" ;;
		claude) printf '%s/.claude/skills' "$HOME" ;;
		opencode) printf '%s/.config/opencode/skills' "$HOME" ;;
		*) printf '%s' "$1" ;;
		esac
	fi
}

ours() {
	# $1: an installed skill path; true when install.sh put it there
	[ -L "$1" ] && case $(readlink -f "$1") in "$here"/skills/*) return 0 ;; esac
	[ -f "$1/.agent-workflow" ]
}

do_install() {
	copy=
	project=
	nobin=
	targets=
	while [ $# -gt 0 ]; do
		case $1 in
		--copy) copy=1 ;;
		--project) project=$(cd "$2" && pwd); shift ;;
		--no-bin) nobin=1 ;;
		-*) die "unknown option $1" ;;
		*) targets="$targets $1" ;;
		esac
		shift
	done
	[ -n "$targets" ] || targets="agents claude"
	for t in $targets; do
		dir=$(resolve "$t")
		mkdir -p "$dir"
		for skill in "$here"/skills/*/; do
			name=$(basename "$skill")
			dest=$dir/$name
			if [ -e "$dest" ] || [ -L "$dest" ]; then
				ours "$dest" || die "$dest exists and was not installed by this script; remove it first"
				rm -rf "$dest"
			fi
			if [ -n "$copy" ]; then
				cp -R "$skill" "$dest" && : >"$dest/.agent-workflow"
			else
				ln -s "$here/skills/$name" "$dest"
			fi
		done
		if [ -n "$copy" ]; then printf 'skills copied into %s\n' "$dir"; else printf 'skills linked into %s\n' "$dir"; fi
	done
	if [ -z "$nobin" ] && [ -z "$project" ]; then
		mkdir -p "$bin"
		ln -sfn "$here/skills/plan-lifecycle/scripts/plan.sh" "$bin/plan-lifecycle"
		ln -sfn "$here/skills/resource-lock/scripts/lock.sh" "$bin/resource-lock"
		printf 'commands plan-lifecycle and resource-lock linked into %s\n' "$bin"
		case :$PATH: in *":$bin:"*) ;; *) printf 'note: %s is not on PATH\n' "$bin" ;; esac
	fi
}

do_uninstall() {
	project=
	targets=
	while [ $# -gt 0 ]; do
		case $1 in
		--project) project=$(cd "$2" && pwd); shift ;;
		-*) die "unknown option $1" ;;
		*) targets="$targets $1" ;;
		esac
		shift
	done
	[ -n "$targets" ] || targets="agents claude opencode"
	for t in $targets; do
		dir=$(resolve "$t")
		for skill in "$here"/skills/*/; do
			dest=$dir/$(basename "$skill")
			{ [ -e "$dest" ] || [ -L "$dest" ]; } || continue
			ours "$dest" && rm -rf "$dest" && printf 'removed %s\n' "$dest"
		done
	done
	if [ -z "$project" ]; then
		for c in plan-lifecycle resource-lock; do
			[ -L "$bin/$c" ] || continue
			case $(readlink -f "$bin/$c") in "$here"/*) rm -f "$bin/$c" && printf 'removed %s\n' "$bin/$c" ;; esac
		done
	fi
	true
}

do_project() {
	[ $# -ge 1 ] || die "usage: project DIR [--base BRANCH]"
	dir=$(cd "$1" && pwd)
	shift
	base=
	while [ $# -gt 0 ]; do
		case $1 in
		--base) base=$2; shift ;;
		*) die "unknown option $1" ;;
		esac
		shift
	done
	git -C "$dir" rev-parse --show-toplevel >/dev/null 2>&1 || die "$dir is not a git worktree"
	plans=$(git -C "$dir" config --get workflow.plans || printf 'docs/plans')
	if [ -e "$dir/AGENTS.md" ]; then
		printf 'AGENTS.md exists; merge %s/templates/AGENTS.md into it by hand\n' "$here"
	else
		cp "$here/templates/AGENTS.md" "$dir/AGENTS.md"
		printf 'AGENTS.md created from the template: fill in every <placeholder>\n'
	fi
	mkdir -p "$dir/$plans"
	[ -e "$dir/$plans/.gitkeep" ] || : >"$dir/$plans/.gitkeep"
	[ -z "$base" ] || git -C "$dir" config workflow.base "$base"
	[ -n "$base" ] || base=$(git -C "$dir" config --get workflow.base || printf '(unset)')
	printf 'plan directory %s; base branch %s\n' "$plans" "$base"
	printf 'next: commit AGENTS.md and %s/.gitkeep on the integration branch\n' "$plans"
}

[ $# -ge 1 ] || { usage >&2; exit 1; }
cmd=$1
shift
case $cmd in
install) do_install "$@" ;;
uninstall) do_uninstall "$@" ;;
project) do_project "$@" ;;
list) for s in "$here"/skills/*/; do printf '%s\n' "$(basename "$s")"; done ;;
-h | --help | help) usage ;;
*) die "unknown command '$cmd'" ;;
esac
