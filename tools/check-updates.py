# SPDX-License-Identifier: GPL-3.0-or-later
"""CI-only stable release check; never installs or mutates the desktop."""
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def json_url(url):
    request = urllib.request.Request(url, headers={"User-Agent": "NovaShell-release-check"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def main():
    requirements = (ROOT / "tests/requirements-ci.txt").read_text()
    pinned_qt = re.search(r"^PySide6-Essentials==([0-9.]+)$", requirements, re.M).group(1)
    runtime = (ROOT / "packaging/runtime.env").read_text()
    pinned_qs = re.search(r"^NOVA_MIN_QUICKSHELL=([0-9.]+)$", runtime, re.M).group(1)
    latest_qt = json_url("https://pypi.org/pypi/PySide6-Essentials/json")["info"]["version"]
    latest_qs = json_url("https://api.github.com/repos/quickshell-mirror/quickshell/releases/latest")["tag_name"].removeprefix("v")
    outdated = []
    for name, current, latest in [("Qt", pinned_qt, latest_qt), ("Quickshell", pinned_qs, latest_qs)]:
        if not re.fullmatch(r"\d+\.\d+\.\d+", latest):
            raise RuntimeError("Unrecognized stable release: " + latest)
        print(f"{name}: configured={current}, stable={latest}")
        if current != latest:
            outdated.append(f"{name} {current} -> {latest}")
    if outdated:
        raise SystemExit("Stable update requires validation: " + ", ".join(outdated))


if __name__ == "__main__":
    main()
