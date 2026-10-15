#!/bin/sh
# lock.sh - exclusive lock on a shared resource (test hardware, a device, a staging host),
# shared by every worktree of the repository. The lock is a directory in the git common
# directory, created atomically with mkdir; the owner is the branch of the current worktree.
set -eu

usage() {
	cat <<'USAGE'
usage: resource-lock take|release|check|status [resource]

  take     <resource>   take the lock or fail showing the current owner
  release  <resource>   release a lock held by the current branch (--force: any owner)
  check    <resource>   exit 0 when the current branch holds the lock, 1 otherwise
  status               list the locks of this repository
USAGE
}

die() {
	printf 'resource-lock: %s\n' "$*" >&2
	exit 1
}

common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) ||
	die "not inside a git repository"
me=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf unknown)

lock_dir() {
	printf '%s' "$1" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$' || die "resource name must be [A-Za-z0-9._-]"
	dir=$common/resource-lock.$1
}

owner_of() {
	[ -f "$1/owner" ] && cat "$1/owner" || printf 'unknown'
}

[ $# -ge 1 ] || { usage >&2; exit 1; }
cmd=$1
shift
case $cmd in
take)
	[ $# -eq 1 ] || die "usage: take <resource>"
	lock_dir "$1"
	if mkdir "$dir" 2>/dev/null; then
		printf '%s since %s\n' "$me" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$dir/owner"
		printf 'lock %s taken by %s\n' "$1" "$me"
	else
		die "lock $1 is held by $(owner_of "$dir")"
	fi
	;;
release)
	force=
	[ "${1-}" = --force ] && { force=1; shift; }
	[ $# -eq 1 ] || die "usage: release [--force] <resource>"
	lock_dir "$1"
	[ -d "$dir" ] || die "lock $1 is not held"
	owner=$(owner_of "$dir")
	case $owner in
	"$me "*) ;;
	*) [ -n "$force" ] || die "lock $1 is held by $owner, not by $me; use --force to break it" ;;
	esac
	rm -rf "$dir"
	printf 'lock %s released\n' "$1"
	;;
check)
	[ $# -eq 1 ] || die "usage: check <resource>"
	lock_dir "$1"
	[ -d "$dir" ] || die "lock $1 is not held"
	case $(owner_of "$dir") in
	"$me "*) printf 'lock %s held by %s\n' "$1" "$me" ;;
	*) die "lock $1 is held by $(owner_of "$dir"), not by $me" ;;
	esac
	;;
status)
	found=
	for d in "$common"/resource-lock.*; do
		[ -d "$d" ] || continue
		found=1
		printf '%s: %s\n' "${d##*/resource-lock.}" "$(owner_of "$d")"
	done
	[ -n "$found" ] || printf 'no lock held\n'
	;;
-h | --help | help) usage ;;
*) die "unknown command '$cmd'" ;;
esac
