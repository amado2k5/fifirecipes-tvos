#!/usr/bin/env python3
"""Turn failed tests in an .xcresult bundle into GitHub Actions annotations.

Usage: ci-annotate-failures.py <bundle.xcresult> [...]

Annotations are readable from the PR checks page and the GitHub API, so the
failing test name and message can be found without downloading the raw job
log or the result bundle. Never fails the step itself.
"""
import json
import subprocess
import sys


def run(args):
    try:
        out = subprocess.run(args, capture_output=True, text=True, timeout=300)
        return out.stdout if out.returncode == 0 else None
    except Exception:
        return None


def esc(s):
    return s.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def failures_new_api(path):
    """Xcode 16+: `xcresulttool get test-results tests`."""
    raw = run(["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", path])
    if not raw:
        return None
    found = []

    def walk(node, trail):
        name = node.get("name", "")
        kind = node.get("nodeType", "")
        if kind == "Test Case" and node.get("result") == "Failed":
            msgs = [c.get("name", "") for c in node.get("children", [])
                    if c.get("nodeType") == "Failure Message"]
            found.append((" / ".join(trail + [name]), msgs or ["(no failure message)"]))
            return
        for c in node.get("children", []):
            walk(c, trail + ([name] if kind in ("Test Suite", "Unit test bundle", "UI test bundle") else []))

    for n in json.loads(raw).get("testNodes", []):
        walk(n, [])
    return found


def failures_legacy(path):
    raw = run(["xcrun", "xcresulttool", "get", "--legacy", "--format", "json", "--path", path])
    if not raw:
        return None
    found = []
    summaries = (json.loads(raw).get("issues", {}) or {}).get("testFailureSummaries", {}) or {}
    for s in summaries.get("_values", []):
        name = s.get("testCaseName", {}).get("_value", "unknown test")
        msg = s.get("message", {}).get("_value", "(no failure message)")
        found.append((name, [msg]))
    return found


def main():
    total = 0
    for path in sys.argv[1:]:
        found = failures_new_api(path)
        if found is None:
            found = failures_legacy(path)
        if found is None:
            print(f"::warning::could not read test results from {path}")
            continue
        for name, msgs in found:
            total += 1
            print(f"::error title=Test failed: {esc(name)[:200]}::{esc(chr(10).join(msgs))[:3000]}")
    print(f"{total} failing test(s) annotated")


if __name__ == "__main__":
    main()
