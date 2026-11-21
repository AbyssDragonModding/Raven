#!/usr/bin/env python3
"""
Brings the Zig layer up to date with Raven: merges the main branch into the
branch of the Zig layer, writes the idiomatic API again from the new headers,
checks that it compiles, commits and pushes.

    python tools/bindgen/update_zig_wrapper.py              merge origin/main into zig-wrapper, regenerate, check, commit, push
    python tools/bindgen/update_zig_wrapper.py --test       also `zig build test` (needs the shared library built from the new headers)
    python tools/bindgen/update_zig_wrapper.py --no-push    everything but the push
    python tools/bindgen/update_zig_wrapper.py --remote upstream --main main --branch zig-wrapper

The same script runs in the workflow bindings/zig/ci/zig-wrapper.yml (once
installed on main as .github/workflows/zig-wrapper.yml) whenever main changes. It stops, changing nothing, when the working tree has changes, when
the merge conflicts, or when the new API does not compile; it goes back to the
branch it started on.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ZIG_DIR = os.path.join(ROOT, "bindings", "zig")


def run(*args, cwd=ROOT, check=True, capture=False):
    print("+ " + " ".join(args), flush=True)
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=capture)
    if check and result.returncode != 0:
        if capture:
            sys.stdout.write(result.stdout)
            sys.stderr.write(result.stderr)
        raise SystemExit("update_zig_wrapper: `%s` failed (%d)" % (" ".join(args), result.returncode))
    return result


def git(*args, **kwargs):
    return run("git", *args, **kwargs)


def output(*args):
    return git(*args, capture=True).stdout.strip()


def sync_package_version():
    """The version of build.zig.zon: the one of the headers."""
    header = open(os.path.join(ROOT, "include", "raven", "raven_core.h"), encoding="utf-8").read()
    parts = [re.search(r"#define\s+RAVEN_VERSION_%s\s+(\d+)" % p, header) for p in ("MAJOR", "MINOR", "PATCH")]
    if not all(parts):
        return
    version = ".".join(m.group(1) for m in parts)
    path = os.path.join(ZIG_DIR, "build.zig.zon")
    text = open(path, encoding="utf-8").read()
    new = re.sub(r'(\.version\s*=\s*")[^"]*(")', r"\g<1>%s\g<2>" % version, text, count=1)
    if new != text:
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(new)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--remote", default="origin", help="the remote of main and of the branch (default: origin)")
    parser.add_argument("--main", default="main", help="the branch of Raven to follow (default: main)")
    parser.add_argument("--branch", default="zig-wrapper", help="the branch of the Zig layer (default: zig-wrapper)")
    parser.add_argument("--test", action="store_true", help="also run `zig build test` (needs the shared library)")
    parser.add_argument("--no-push", action="store_true", help="commit, but do not push")
    parser.add_argument("--zig", default=shutil.which("zig"), help="the zig to check with (default: on the PATH)")
    args = parser.parse_args()

    if output("status", "--porcelain", "--untracked-files=no"):
        raise SystemExit("update_zig_wrapper: the working tree has changes; commit or stash them first")
    start = output("rev-parse", "--abbrev-ref", "HEAD")
    git("fetch", args.remote)
    upstream = "%s/%s" % (args.remote, args.main)
    try:
        # the branch, as it is on the remote when it is there
        remote_branch = "%s/%s" % (args.remote, args.branch)
        has_remote = git("rev-parse", "--verify", "--quiet", remote_branch, check=False, capture=True).returncode == 0
        has_local = git("rev-parse", "--verify", "--quiet", args.branch, check=False, capture=True).returncode == 0
        if has_local:
            git("switch", args.branch)
            if has_remote:
                git("merge", "--ff-only", remote_branch)
        elif has_remote:
            git("switch", "-c", args.branch, "--track", remote_branch)
        else:
            raise SystemExit("update_zig_wrapper: no branch %s here or on %s" % (args.branch, args.remote))

        # ---- Raven's changes
        main_commit = output("rev-parse", "--short", upstream)
        if git("merge-base", "--is-ancestor", upstream, "HEAD", check=False).returncode != 0:
            merged = git("merge", "--no-edit", "-m", "Merge %s (%s) into %s" % (upstream, main_commit, args.branch), upstream, check=False)
            if merged.returncode != 0:
                git("merge", "--abort", check=False)
                raise SystemExit("update_zig_wrapper: merging %s conflicts: merge it by hand, then run this again" % upstream)
        else:
            print("%s is already merged" % upstream)

        # ---- the API again, from the new headers
        run(sys.executable, os.path.join(ROOT, "tools", "bindgen", "gen_zig_wrapper.py"))
        sync_package_version()
        report = open(os.path.join(ZIG_DIR, "FALLBACKS.md"), encoding="utf-8").read()
        mapped_all = "Nothing: every function" in report
        if not mapped_all:
            print("note: some of the new API is written with the types of C, see bindings/zig/FALLBACKS.md")

        # ---- it compiles (and runs)
        if not args.zig:
            raise SystemExit("update_zig_wrapper: zig (0.17) is needed to check the new API (--zig <path>)")
        run(args.zig, "fmt", "--check", "src", "build.zig", "build.zig.zon", "example", cwd=ZIG_DIR)
        run(args.zig, "build", "check", "--summary", "all", cwd=ZIG_DIR)
        if args.test:
            run(args.zig, "build", "test", "--summary", "all", cwd=ZIG_DIR)

        # ---- commit, push
        git("add", "bindings/zig", "tools/bindgen/gen_zig_wrapper.py")
        if git("diff", "--cached", "--quiet", check=False).returncode != 0:
            git("commit", "-m", "Zig: the idiomatic API regenerated for %s (%s)%s" % (
                upstream, main_commit, "" if mapped_all else "\n\nSome of it keeps the types of C: see bindings/zig/FALLBACKS.md."))
        else:
            print("the Zig layer did not change")
        if not args.no_push:
            git("push", args.remote, "%s:%s" % (args.branch, args.branch))
    finally:
        if output("rev-parse", "--abbrev-ref", "HEAD") != start and start != "HEAD":
            git("switch", start, check=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
