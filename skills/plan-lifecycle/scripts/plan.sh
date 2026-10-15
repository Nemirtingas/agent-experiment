#!/bin/sh
# plan.sh - task branches, plan files and the integration merge of the agent workflow.
# POSIX sh; runs from any checkout of the repository. Settings are git config keys:
#   workflow.base       default base branch for branch, propose, merge, drop and status
#   workflow.plans      directory of the plan files, relative to the repository root
#                       (default docs/plans)
#   workflow.worktrees  directory that receives the task worktrees
#                       (default: the directory above the main worktree)
set -eu

self=$(readlink -f "$0" 2>/dev/null || realpath "$0")
template=$(dirname "$(dirname "$self")")/assets/PLAN.md

usage() {
	cat <<'USAGE'
usage: plan-lifecycle <command> [arguments]

  branch   <type> <name> [base]  light path: task branch and worktree, no plan file
  propose  <type> <name> [base]  plan path: task branch and worktree with a pending plan
  validate <type> <name>         mark the committed plan validated and commit
  merge    <branch> [base]       integrate: fetch, fast-forward the base, merge --no-ff
                                 with the message on stdin, drop the branch and worktree
  drop     <branch> [base]       remove a merged branch and its worktree
  status   [base]                open task branches, their plans and worktrees
  config   [key [value]]         show or set workflow.base, workflow.plans, workflow.worktrees

<type> is fix, feature or docs; <name> is lowercase kebab-case.
Plan ID and worktree name: <type>_<name>. Branch: <type>/<name>.
USAGE
}

die() {
	printf 'plan-lifecycle: %s\n' "$*" >&2
	exit 1
}

cfg() {
	git config --get "workflow.$1" 2>/dev/null || printf '%s' "${2-}"
}

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) ||
	die "not inside a git repository"
main_wt=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
if git worktree list --porcelain | sed -n '2p' | grep -qx bare && [ "$main_wt/.git" = "$common" ]; then
	default_root=$main_wt # bare repository at <dir>/.git: worktrees are children of <dir>
else
	default_root=$(dirname "$main_wt") # worktrees are siblings of the main checkout
fi
root=$(cfg worktrees "$default_root")
plans=$(cfg plans docs/plans)

base_of() {
	base=${1:-$(cfg base)}
	[ -n "$base" ] || die "no base branch: give it as an argument or set 'git config workflow.base <branch>'"
	git rev-parse --verify -q "refs/heads/$base" >/dev/null || die "no local branch '$base'"
}

check_id() {
	case $1 in fix | feature | docs) ;; *) die "type must be fix, feature or docs" ;; esac
	printf '%s' "$2" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || die "name must be lowercase kebab-case"
	type=$1
	name=$2
	id=${1}_$2
	branch=$1/$2
	words=$(printf '%s' "$2" | tr '-' ' ')
}

id_of_branch() {
	case $1 in
	fix/* | feature/* | docs/*) check_id "${1%%/*}" "${1#*/}" ;;
	*) die "branch must be fix/<name>, feature/<name> or docs/<name>" ;;
	esac
}

worktree_of() {
	git worktree list --porcelain |
		awk -v b="refs/heads/$1" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w; exit}'
}

clean() {
	[ -z "$(git -C "$1" status --porcelain)" ] || die "worktree $1 has uncommitted changes"
}

plan_status() {
	# $1: a ref or a worktree path; prints none, pending, validated or finished
	st=
	if [ -d "$1" ]; then
		[ ! -f "$1/$plans/$id.md" ] || st=$(sed -n 's/^- Status: *//p' "$1/$plans/$id.md" | head -1)
	elif git cat-file -e "$1:$plans/$id.md" 2>/dev/null; then
		st=$(git show "$1:$plans/$id.md" | sed -n 's/^- Status: *//p' | head -1)
	fi
	printf '%s' "${st:-none}"
}

sync_base() {
	# Fetch the base branch's upstream and fast-forward; stop when they diverged.
	upstream=$(git rev-parse --abbrev-ref -q "$base@{upstream}" 2>/dev/null) ||
		{ printf 'note: %s has no upstream; nothing fetched\n' "$base"; return 0; }
	remote=${upstream%%/*}
	git fetch --quiet "$remote" || die "fetch from $remote failed; not continuing from a stale base"
	local_rev=$(git rev-parse "refs/heads/$base")
	remote_rev=$(git rev-parse "refs/remotes/$upstream")
	[ "$local_rev" = "$remote_rev" ] && return 0
	if git merge-base --is-ancestor "$local_rev" "$remote_rev"; then
		if [ -n "$base_wt" ]; then
			clean "$base_wt"
			git -C "$base_wt" merge --quiet --ff-only "$upstream"
		else
			git fetch --quiet "$remote" "${upstream#*/}:$base"
		fi
		printf 'fast-forwarded %s to %s\n' "$base" "$upstream"
	elif git merge-base --is-ancestor "$remote_rev" "$local_rev"; then
		printf 'fetched %s; %s is ahead of it, no fast-forward needed\n' "$upstream" "$base"
	else
		die "$base and $upstream have diverged; merge $upstream into $base in its worktree first"
	fi
}

new_worktree() {
	base_of "${3-}"
	base_wt=$(worktree_of "$base")
	check_id "$1" "$2"
	! git rev-parse --verify -q "refs/heads/$branch" >/dev/null || die "branch $branch already exists"
	[ ! -e "$root/$id" ] || die "$root/$id already exists"
	sync_base
	git worktree add --quiet -b "$branch" "$root/$id" "$base"
	printf 'branch %s from %s at %s\nworktree %s\n' "$branch" "$base" "$(git rev-parse --short "$base")" "$root/$id"
}

cmd_branch() {
	[ $# -ge 2 ] || die "usage: branch <type> <name> [base]"
	new_worktree "$@"
}

cmd_propose() {
	[ $# -ge 2 ] || die "usage: propose <type> <name> [base]"
	[ -f "$template" ] || die "plan template missing: $template"
	new_worktree "$@"
	mkdir -p "$root/$id/$plans"
	sed -e "s|<type>_<plan-name>|$id|" -e "s|<fix.feature.docs>|$type|" "$template" >"$root/$id/$plans/$id.md"
	printf 'plan %s (pending, not committed): the Planner writes and commits it\n' "$root/$id/$plans/$id.md"
}

cmd_validate() {
	[ $# -eq 2 ] || die "usage: validate <type> <name>"
	check_id "$1" "$2"
	wt=$(worktree_of "$branch")
	[ -n "$wt" ] || die "branch $branch has no worktree"
	clean "$wt"
	file=$wt/$plans/$id.md
	[ -f "$file" ] || die "no plan file $file"
	case $(plan_status "$wt") in
	pending) ;;
	validated) die "plan $id is already validated; to amend it, the Planner sets Status back to pending" ;;
	*) die "plan $id has an unexpected status; expected 'pending'" ;;
	esac
	sed -i.bak 's/^- Status: *pending.*/- Status: validated/' "$file" && rm -f "$file.bak"
	git -C "$wt" add "$plans/$id.md"
	git -C "$wt" commit --quiet -m "Validate the $words plan"
	printf 'plan %s validated: %s\n' "$id" "$(git -C "$wt" rev-parse --short HEAD)"
}

cmd_merge() {
	[ $# -ge 1 ] || die "usage: merge <branch> [base] < message"
	[ ! -t 0 ] || die "give the merge message on stdin"
	msg=$(cat)
	[ -n "$msg" ] || die "empty merge message"
	id_of_branch "$1"
	base_of "${2-}"
	git rev-parse --verify -q "refs/heads/$branch" >/dev/null || die "no branch $branch"
	base_wt=$(worktree_of "$base")
	[ -n "$base_wt" ] || die "check out $base in a worktree before merging into it"
	clean "$base_wt"
	sync_base
	case $(plan_status "refs/heads/$branch") in
	none | finished) ;;
	validated)
		wt=$(worktree_of "$branch")
		[ -n "$wt" ] || die "branch $branch has no worktree to finish its plan in"
		clean "$wt"
		sed -i.bak 's/^- Status: *validated.*/- Status: finished/' "$wt/$plans/$id.md" && rm -f "$wt/$plans/$id.md.bak"
		git -C "$wt" add "$plans/$id.md"
		git -C "$wt" commit --quiet -m "Finish the $words plan"
		;;
	pending) die "plan $id is still pending; validate it before merging" ;;
	*) die "plan $id has an unexpected status" ;;
	esac
	if ! git -C "$base_wt" merge --quiet --no-ff -m "$msg" "$branch"; then
		git -C "$base_wt" merge --abort 2>/dev/null || true
		die "merge of $branch into $base failed and was aborted:" \
			"merge $base into $branch in its worktree, resolve, re-review, then retry"
	fi
	printf 'merged %s into %s: %s\n' "$branch" "$base" "$(git -C "$base_wt" rev-parse --short HEAD)"
	drop_branch
}

drop_branch() {
	git merge-base --is-ancestor "refs/heads/$branch" "refs/heads/$base" ||
		die "$branch is not merged into $base; keeping it"
	wt=$(worktree_of "$branch")
	if [ -n "$wt" ]; then
		git worktree remove "$wt" || die "worktree $wt kept (uncommitted changes?); branch $branch kept"
	fi
	git branch --quiet -D "$branch"
	printf 'dropped %s%s\n' "$branch" "${wt:+ and $wt}"
}

cmd_drop() {
	[ $# -ge 1 ] || die "usage: drop <branch> [base]"
	id_of_branch "$1"
	base_of "${2-}"
	drop_branch
}

cmd_status() {
	base=${1:-$(cfg base)}
	printf 'base: %s   plans: %s   worktrees: %s\n' "${base:-(unset)}" "$plans" "$root"
	git for-each-ref --format='%(refname:short)' 'refs/heads/fix/' 'refs/heads/feature/' 'refs/heads/docs/' |
		while read -r b; do
			[ "$b" != "$base" ] || continue
			# A task branch has a worktree, or at least a plan file; other fix/feature/docs branches are not listed.
			case ${b#*/} in *[!a-z0-9-]* | -* | *-) continue ;; esac
			id_of_branch "$b"
			wt=$(worktree_of "$b")
			if [ -n "$wt" ]; then
				state=$(plan_status "$wt")
				[ -z "$(git -C "$wt" status --porcelain)" ] && dirt=clean || dirt=dirty
			else
				state=$(plan_status "refs/heads/$b")
				[ "$state" != none ] || continue
				dirt="no worktree"
			fi
			rel=
			if [ -n "$base" ] && git rev-parse --verify -q "refs/heads/$base" >/dev/null; then
				rel=$(git rev-list --left-right --count "$base...$b" |
					awk '{printf "behind %s, ahead %s", $1, $2}')
				git merge-base --is-ancestor "$b" "$base" && rel="merged, drop it"
			fi
			printf '%-28s plan %-10s %-12s %s %s\n' "$b" "$state" "$dirt" "$rel" "${wt:+ $wt}"
		done
}

cmd_config() {
	case $# in
	0)
		for key in base plans worktrees; do
			if value=$(git config --get "workflow.$key" 2>/dev/null); then
				printf '%-10s %s\n' "$key" "$value"
			else
				case $key in base) value='(unset)' ;; plans) value="$plans (default)" ;; worktrees) value="$root (default)" ;; esac
				printf '%-10s %s\n' "$key" "$value"
			fi
		done
		;;
	1) git config --get "workflow.$1" ;;
	2) git config "workflow.$1" "$2" ;;
	*) die "usage: config [key [value]]" ;;
	esac
}

[ $# -ge 1 ] || { usage >&2; exit 1; }
cmd=$1
shift
case $cmd in
branch | propose | validate | merge | drop | status | config) "cmd_$cmd" "$@" ;;
-h | --help | help) usage ;;
*) die "unknown command '$cmd'" ;;
esac
