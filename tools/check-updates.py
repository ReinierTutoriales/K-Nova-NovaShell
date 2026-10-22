# SPDX-License-Identifier: GPL-3.0-or-later
"""CI-only stable release check; never installs or mutates the desktop.

Quickshell is read from the mirror's git tags, not from GitHub Releases:
the mirror only publishes some tags as releases (its "latest" release can
lag several patch versions behind the newest tag).
"""
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
STABLE = re.compile(r"v?(\d+)\.(\d+)\.(\d+)")
QUICKSHELL_TAGS = "https://api.github.com/repos/quickshell-mirror/quickshell/tags?per_page=100"


def json_url(url):
    request = urllib.request.Request(url, headers={"User-Agent": "NovaShell-release-check"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def parse(version):
    match = STABLE.fullmatch(version)
    return tuple(map(int, match.groups())) if match else None


def latest_stable(versions):
    """Highest X.Y.Z among the given strings (an optional "v" prefix is allowed)."""
    stable = [parsed for parsed in map(parse, versions) if parsed]
    if not stable:
        raise RuntimeError("No stable release found")
    return ".".join(map(str, max(stable)))


def evaluate(pairs):
    """Return (messages, outdated) for (name, configured, latest) triples.

    Only a newer upstream version counts as outdated. A configured version
    above the newest upstream one means the data source is wrong, which is
    an error rather than an update.
    """
    messages, outdated = [], []
    for name, current, latest in pairs:
        configured, upstream = parse(current), parse(latest)
        if configured is None or upstream is None:
            raise RuntimeError(f"Unrecognized version for {name}: {current!r} / {latest!r}")
        messages.append(f"{name}: configured={current}, stable={latest}")
        if upstream > configured:
            outdated.append(f"{name} {current} -> {latest}")
        elif upstream < configured:
            raise RuntimeError(f"{name} {current} is newer than the upstream source ({latest})")
    return messages, outdated


def main():
    requirements = (ROOT / "tests/requirements-ci.txt").read_text()
    pinned_qt = re.search(r"^PySide6-Essentials==([0-9.]+)$", requirements, re.M).group(1)
    runtime = (ROOT / "packaging/runtime.env").read_text()
    pinned_qs = re.search(r"^NOVA_MIN_QUICKSHELL=([0-9.]+)$", runtime, re.M).group(1)

    qt_releases = json_url("https://pypi.org/pypi/PySide6-Essentials/json")["releases"]
    latest_qt = latest_stable(version for version, files in qt_releases.items()
                              if any(not item.get("yanked", False) for item in files))
    latest_qs = latest_stable(tag["name"] for tag in json_url(QUICKSHELL_TAGS))

    messages, outdated = evaluate([("Qt", pinned_qt, latest_qt),
                                   ("Quickshell", pinned_qs, latest_qs)])
    print("\n".join(messages))
    artwork = json.loads((ROOT / "assets/goldengate-library.json").read_text())
    release = json_url("https://api.github.com/repos/PuzzlePieceee/Golden-Gate-app-icons-by-PVZL/releases/latest")
    latest_artwork = release["tag_name"]
    print(f"GoldenGate: configured={artwork['release']}, stable={latest_artwork}")
    if artwork["release"] != latest_artwork:
        outdated.append(f"GoldenGate {artwork['release']} -> {latest_artwork}")
    if outdated:
        raise SystemExit("Stable update requires validation: " + ", ".join(outdated))


if __name__ == "__main__":
    main()
