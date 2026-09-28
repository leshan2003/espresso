"""Audit the exact staged Git snapshot before publication (standard library only)."""
from pathlib import Path, PurePosixPath
import json
import re
import subprocess
import sys

ROOT_FILES = {".gitignore", ".gitattributes", "README.md", "NOTICE.md",
              "CITATION.cff", "CMakeLists.txt", "requirements.txt"}
PREFIXES = ("src/cost_model/", "src/cost_model_cpp/", "hardware/", "examples/",
            "results/resource/", "docs/", "tools/", ".github/workflows/")
EXACT_FILES = {"papers/README.md", "slides/README.md", "slides/espresso-overview.md", "results/README.md"}
FORBIDDEN_PARTS = {"archive", "private", "local", ".git", "__pycache__", "build", ".vscode"}
ALLOWED_SUFFIXES = {".md", ".py", ".cpp", ".h", ".hpp", ".json", ".v", ".tcl", ".txt", ".csv", ".png", ".yml", ".cff"}
SECRETS = re.compile(rb"(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----)")


def local_exclusions():
    policy = Path(__file__).resolve().parents[1] / "private/release-policy.json"
    if not policy.exists():
        return None
    terms = json.loads(policy.read_text(encoding="utf-8"))["excluded_terms"]
    if not isinstance(terms, list) or not terms or not all(isinstance(term, str) and term for term in terms):
        raise ValueError("Local release policy must contain nonempty exclusion terms")
    return re.compile("|".join(re.escape(term) for term in terms), re.IGNORECASE)


def git(*args):
    return subprocess.check_output(["git", *args])


def main():
    excluded = local_exclusions()
    entries = git("ls-files", "--stage", "-z").split(b"\0")
    errors, total, count = [], 0, 0
    for entry in entries:
        if not entry:
            continue
        metadata, raw_path = entry.split(b"\t", 1)
        mode, oid, stage = metadata.decode().split()
        name = raw_path.decode("utf-8")
        path = PurePosixPath(name)
        count += 1
        if mode not in {"100644", "100755"} or stage != "0":
            errors.append(f"Non-regular or conflicted entry: {name}")
            continue
        if name not in ROOT_FILES | EXACT_FILES and not name.startswith(PREFIXES):
            errors.append(f"Outside reviewed release roots: {name}")
        if any(part.lower() in FORBIDDEN_PARTS for part in path.parts):
            errors.append(f"Local/private path: {name}")
        if name not in ROOT_FILES and path.name != "LICENSE.nlohmann-json" and path.suffix not in ALLOWED_SUFFIXES:
            errors.append(f"Unreviewed file type: {name}")
        size = int(git("cat-file", "-s", oid))
        total += size
        if size > 20 * 1024 * 1024:
            errors.append(f"Unexpected large file: {name}")
            continue
        data = git("cat-file", "blob", oid)
        if SECRETS.search(data):
            errors.append(f"Credential marker: {name}")
        if excluded and (excluded.search(name) or excluded.search(data.decode("utf-8", errors="replace"))):
            errors.append(f"Excluded material: {name}")
        if path.suffix != ".png" and name != "tools/audit_release.py":
            if re.search(rb"[A-Za-z]:[/\\](?:Users|Academy|Event)|/home/[^/]+/", data):
                errors.append(f"Machine-specific path: {name}")
    if not count:
        errors.append("Empty Git index")
    for error in errors:
        print(error, file=sys.stderr)
    print(f"Audited {count} staged files, {total / 1024**2:.2f} MiB, {len(errors)} failures.")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
