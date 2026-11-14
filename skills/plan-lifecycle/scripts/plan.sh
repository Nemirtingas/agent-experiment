#!/bin/sh
# plan.sh - task branches, plan folders and the integration merge of the agent workflow.
# POSIX sh; runs from any checkout of the repository. Settings are git config keys:
#   workflow.base       default base branch for propose, merge, drop and status
#   workflow.plans      directory of the plan folders, relative to the repository root
#                       (default docs/plans)
#   workflow.worktrees  directory that receives the task worktrees
#                       (default: the directory above the main worktree)
set -eu

self=$(readlink -f "$0" 2>/dev/null || realpath "$0")
assets=$(dirname "$(dirname "$self")")/assets

usage() {
	cat <<'USAGE'
usage: plan-lifecycle <command> [arguments]

  propose  <type> <name> [base]  task branch and worktree with a pending plan folder
  task     <type> <name> <n> [s] seed the files of task <n>, or of its slice <s>, in a
                                 pending plan
  validate <type> <name> [mode]  mark the committed plan validated and commit; mode is
                                 automatic (default) or interactive
  mode     <type> <name> [mode]  show the plan's mode, or change it and commit
  close    <type> <name> <n> [s] mark a finished task or slice done and commit it with
                                 its evidence file
  merge    <branch> [base]       integrate: fetch, fast-forward the base, merge --no-ff
                                 with the message on stdin, drop the branch and worktree
  drop     <branch> [base]       remove a merged branch and its worktree
  status   [base]                open task branches, their plans and worktrees
  config   [key [value]]         show or set workflow.base, workflow.plans, workflow.worktrees
  quota    [provider [level]]    show or record, for this user on this machine, how much
                                 quota a provider's subscription leaves: low or high

<type> is fix, feature or docs; <name> is lowercase kebab-case.
Branch: <type>/<name>. Worktree: <type>_<name>. Plan ID: M<number>_<name>, a milestone;
propose gives it the next free number. <n> is the task number, <s> one lowercase
letter: task 1 is Task1, its slice a is Task1a. Plan folder: <plans>/<plan ID>/ with
<plan ID>.md and one folder per task.
USAGE
}

die() {
	printf 'plan-lifecycle: %s\n' "$*" >&2
	exit 1
}

cfg() {
	git config --get "workflow.$1" 2>/dev/null || printf '%s' "${2-}"
}

cmd_quota() {
	# User-wide, in the global git configuration: workflow.quota.<provider> = low | high
	case $# in
	0)
		recorded=$(git config --global --get-regexp '^workflow\.quota\.' 2>/dev/null || true)
		if [ -n "$recorded" ]; then
			printf '%s\n' "$recorded" | sed 's/^workflow\.quota\.//'
		else
			printf 'no quota recorded: every provider counts as low\n'
		fi
		;;
	1) git config --global --get "workflow.quota.$1" 2>/dev/null || printf 'low (not recorded)\n' ;;
	2)
		printf '%s' "$1" | grep -Eq '^[a-z0-9]+$' || die "the provider is one lowercase word: claude, codex"
		case $2 in low | high) ;; *) die "the level is low or high" ;; esac
		git config --global "workflow.quota.$1" "$2"
		printf 'quota %s %s\n' "$1" "$2"
		;;
	*) die "usage: quota [provider [low|high]]" ;;
	esac
}

# Commands that need no repository.
case ${1-} in
quota)
	shift
	cmd_quota "$@"
	exit 0
	;;
-h | --help | help)
	usage
	exit 0
	;;
esac

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
	wt_name=${1}_$2
	branch=$1/$2
	words=$(printf '%s' "$2" | tr '-' ' ')
	find_id
}

find_id() {
	# The plan ID of $branch, M<number>_<name>: recorded by propose in the branch's configuration,
	# else the highest-numbered plan folder of that name committed on the branch. Empty when none.
	id=$(git config --get "branch.$branch.plan" 2>/dev/null) && return 0
	id=$(git ls-tree -d --name-only "refs/heads/$branch" "$plans/" 2>/dev/null |
		sed -n "s|^.*/\\(M[0-9][0-9]*_$name\\)\$|\\1|p" |
		awk -F'[M_]' '$2 + 0 >= n {n = $2 + 0; id = $0} END {print id}')
}

need_id() {
	[ -n "$id" ] || die "branch $branch has no plan; create it with 'propose $type $name'"
}

next_number() {
	# One more than the highest milestone number on the base, the task branches and their worktrees.
	{
		for ref in "$base" $(git for-each-ref --format='%(refname:short)' \
			refs/heads/fix/ refs/heads/feature/ refs/heads/docs/); do
			git ls-tree -d --name-only "refs/heads/$ref" "$plans/" 2>/dev/null || true
		done
		git worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r w; do
			for d in "$w/$plans"/M[0-9]*_*/; do
				[ ! -d "$d" ] || printf '%s\n' "${d%/}"
			done
		done
	} | sed -n 's|^.*/M\([0-9][0-9]*\)_[^/]*$|\1|p' | awk '$1 + 0 > n {n = $1 + 0} END {print n + 1}'
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
	if [ -z "$id" ]; then
		:
	elif [ -d "$1" ]; then
		[ ! -f "$1/$plans/$id/$id.md" ] || st=$(sed -n 's/^- Status: *//p' "$1/$plans/$id/$id.md" | head -1)
	elif git cat-file -e "$1:$plans/$id/$id.md" 2>/dev/null; then
		st=$(git show "$1:$plans/$id/$id.md" | sed -n 's/^- Status: *//p' | head -1)
	fi
	printf '%s' "${st:-none}"
}

set_status() {
	# $1: file, $2: expected status, $3: new status
	sed "s/^- Status: *$2.*/- Status: $3/" "$1" >"$1.new" && mv -f "$1.new" "$1"
}

check_mode() {
	case $1 in automatic | interactive) ;; *) die "the mode is automatic or interactive" ;; esac
}

set_mode() {
	# $1: plan file, $2: automatic or interactive
	grep -q '^- Mode: ' "$1" || die "$1 has no '- Mode:' line"
	sed "s/^- Mode: .*/- Mode: $2/" "$1" >"$1.new" && mv -f "$1.new" "$1"
}

check_unit() {
	# $1: task number, $2: optional slice letter; a unit is a task without slices, or a slice
	printf '%s' "$1" | grep -Eq '^[1-9][0-9]*$' || die "the task is a number: 1 for Task1"
	task=Task$1
	if [ -n "${2-}" ]; then
		printf '%s' "$2" | grep -Eq '^[a-z]$' || die "the slice is one lowercase letter: a for ${task}a"
		unit=$task$2
		unit_dir=$task/$unit
	else
		unit=$task
		unit_dir=$task
	fi
}

count_units() {
	# $1: a plan folder; sets total and open (units whose status is not done)
	total=0
	open=0
	for f in "$1"/Task*/Task*.md "$1"/Task*/Task*/Task*.md; do
		[ -f "$f" ] || continue
		case $f in *_evidence.md) continue ;; esac
		total=$((total + 1))
		[ "$(sed -n 's/^- Status: *//p' "$f" | head -1)" = done ] || open=$((open + 1))
	done
}

plan_worktree() {
	# the worktree of $branch, required
	wt=$(worktree_of "$branch")
	[ -n "$wt" ] || die "branch $branch has no worktree"
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
	[ ! -e "$root/$wt_name" ] || die "$root/$wt_name already exists"
	sync_base
	git worktree add --quiet -b "$branch" "$root/$wt_name" "$base"
	printf 'branch %s from %s at %s\nworktree %s\n' "$branch" "$base" "$(git rev-parse --short "$base")" \
		"$root/$wt_name"
}

cmd_propose() {
	[ $# -ge 2 ] || die "usage: propose <type> <name> [base]"
	[ -f "$assets/PLAN.md" ] || die "plan template missing: $assets/PLAN.md"
	new_worktree "$@"
	id=M$(next_number)_$name
	git config "branch.$branch.plan" "$id"
	mkdir -p "$root/$wt_name/$plans/$id"
	sed -e "s|<plan-id>|$id|g" -e "s|<fix.feature.docs>|$type|" "$assets/PLAN.md" >"$root/$wt_name/$plans/$id/$id.md"
	printf 'plan %s (pending, not committed): the Planner writes it, seeds its tasks and commits\n' \
		"$root/$wt_name/$plans/$id/$id.md"
}

cmd_task() {
	[ $# -eq 3 ] || [ $# -eq 4 ] || die "usage: task <type> <name> <number> [slice]"
	[ -f "$assets/TASK.md" ] && [ -f "$assets/EVIDENCE.md" ] || die "task templates missing in $assets"
	check_id "$1" "$2"
	check_unit "$3" "${4-}"
	need_id
	plan_worktree
	dir=$wt/$plans/$id
	case $(plan_status "$wt") in
	pending) ;;
	none) die "no plan file $dir/$id.md" ;;
	*) die "plan $id is not pending; its tasks change only through an amendment, which sets Status back to pending" ;;
	esac
	[ ! -e "$dir/$unit_dir/$unit.md" ] || die "$dir/$unit_dir/$unit.md already exists"
	if [ "$unit" = "$task" ]; then
		for d in "$dir/$task/$task"[a-z]; do
			[ ! -e "$d" ] || die "$task already has slices; add a slice instead of the whole task"
		done
	else
		[ ! -e "$dir/$task/$task.md" ] || die "$task is a whole task; remove its files before slicing it"
	fi
	mkdir -p "$dir/$unit_dir"
	sed -e "s|<unit>|$unit|g" -e "s|<plan-id>|$id|g" "$assets/TASK.md" >"$dir/$unit_dir/$unit.md"
	sed -e "s|<unit>|$unit|g" -e "s|<plan-id>|$id|g" "$assets/EVIDENCE.md" >"$dir/$unit_dir/${unit}_evidence.md"
	printf 'unit %s (todo, not committed)\nevidence %s\n' "$dir/$unit_dir/$unit.md" "$dir/$unit_dir/${unit}_evidence.md"
}

cmd_validate() {
	[ $# -eq 2 ] || [ $# -eq 3 ] || die "usage: validate <type> <name> [automatic|interactive]"
	check_id "$1" "$2"
	[ $# -eq 2 ] || check_mode "$3"
	need_id
	plan_worktree
	clean "$wt"
	file=$wt/$plans/$id/$id.md
	[ -f "$file" ] || die "no plan file $file"
	case $(plan_status "$wt") in
	pending) ;;
	validated) die "plan $id is already validated; to amend it, the Planner sets Status back to pending" ;;
	*) die "plan $id has an unexpected status; expected 'pending'" ;;
	esac
	count_units "$wt/$plans/$id"
	[ "$total" -gt 0 ] || die "plan $id has no task; seed at least one with 'task $type $name 1'"
	[ $# -eq 2 ] || set_mode "$file" "$3"
	set_status "$file" pending validated
	git -C "$wt" add "$plans/$id/$id.md"
	git -C "$wt" commit --quiet -m "Validate the $words plan"
	printf 'plan %s validated, %s mode, %s unit(s), %s to do: %s\n' "$id" \
		"$(sed -n 's/^- Mode: *//p' "$file" | head -1)" "$total" "$open" "$(git -C "$wt" rev-parse --short HEAD)"
}

cmd_mode() {
	[ $# -eq 2 ] || [ $# -eq 3 ] || die "usage: mode <type> <name> [automatic|interactive]"
	check_id "$1" "$2"
	[ $# -eq 2 ] || check_mode "$3"
	need_id
	plan_worktree
	file=$wt/$plans/$id/$id.md
	[ -f "$file" ] || die "no plan file $file"
	current=$(sed -n 's/^- Mode: *//p' "$file" | head -1)
	if [ $# -eq 2 ] || [ "$current" = "$3" ]; then
		printf '%s\n' "${current:-automatic}"
		return 0
	fi
	clean "$wt"
	set_mode "$file" "$3"
	git -C "$wt" add "$plans/$id/$id.md"
	git -C "$wt" commit --quiet -m "Run the $words plan in $3 mode"
	printf 'plan %s now in %s mode: %s\n' "$id" "$3" "$(git -C "$wt" rev-parse --short HEAD)"
}

cmd_close() {
	[ $# -eq 3 ] || [ $# -eq 4 ] || die "usage: close <type> <name> <number> [slice]"
	check_id "$1" "$2"
	check_unit "$3" "${4-}"
	need_id
	plan_worktree
	file=$plans/$id/$unit_dir/$unit.md
	evidence=$plans/$id/$unit_dir/${unit}_evidence.md
	[ -f "$wt/$file" ] || die "no unit file $wt/$file"
	[ -f "$wt/$evidence" ] || die "no evidence file $wt/$evidence"
	[ "$(plan_status "$wt")" = validated ] || die "plan $id is not validated"
	case $(sed -n 's/^- Status: *//p' "$wt/$file" | head -1) in
	todo) ;;
	done) die "$unit is already done" ;;
	*) die "$unit has an unexpected status; expected 'todo'" ;;
	esac
	! grep -q '^- Agent: <' "$wt/$evidence" ||
		die "$evidence still has the template's placeholders; the Developer fills it first"
	case $(sed -n 's/^- Review: *//p' "$wt/$file" | head -1) in
	no) ;;
	*)
		grep -q '^Reviewed-by: ' "$wt/$evidence" ||
			die "$unit asks for a review and $evidence has no 'Reviewed-by: ' line; record the approving review first"
		;;
	esac
	other=$(git -C "$wt" status --porcelain --untracked-files=all | grep -v -F -e "$file" -e "$evidence" || true)
	[ -z "$other" ] || die "worktree $wt has other uncommitted changes; commit the work of $unit first"
	set_status "$wt/$file" todo done
	git -C "$wt" add "$file" "$evidence"
	git -C "$wt" commit --quiet -m "Close $unit of the $words plan"
	count_units "$wt/$plans/$id"
	printf '%s done: %s; %s of %s unit(s) left\n' "$unit" "$(git -C "$wt" rev-parse --short HEAD)" "$open" "$total"
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
	finished) ;;
	validated)
		wt=$(worktree_of "$branch")
		[ -n "$wt" ] || die "branch $branch has no worktree to finish its plan in"
		clean "$wt"
		count_units "$wt/$plans/$id"
		[ "$open" -eq 0 ] || die "plan $id has $open of $total unit(s) not done; close them before merging"
		set_status "$wt/$plans/$id/$id.md" validated finished
		git -C "$wt" add "$plans/$id/$id.md"
		git -C "$wt" commit --quiet -m "Finish the $words plan"
		;;
	pending) die "plan $id is still pending; validate it before merging" ;;
	none) die "branch $branch has no committed plan under $plans; every change is merged with its plan" ;;
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
			units=
			if [ -n "$wt" ]; then
				state=$(plan_status "$wt")
				[ -z "$(git -C "$wt" status --porcelain)" ] && dirt=clean || dirt=dirty
				count_units "$wt/$plans/$id"
				units="units $((total - open))/$total done"
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
			printf '%-24s %-20s plan %-10s %-16s %-12s %s %s\n' "$b" "${id:--}" "$state" "$units" "$dirt" "$rel" \
				"${wt:+ $wt}"
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
propose | task | validate | mode | close | merge | drop | status | config) "cmd_$cmd" "$@" ;;
-h | --help | help) usage ;;
*) die "unknown command '$cmd'" ;;
esac
