"""Build the release ZIP with Python's standard library."""
from pathlib import Path
import re
import shutil
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def copy_project(destination):
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copytree(ROOT / "addons", destination / "addons")
    for source in (ROOT / "sample_project").iterdir():
        if source.is_file() and source.name != "addons":
            shutil.copy2(source, destination / source.name)


def main():
    version = re.search(r'^const VERSION := "([^"]+)"', (ROOT / "addons/render_lens/mcp_server.gd").read_text(), re.M).group(1)
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="render-lens-packages-") as scratch:
        package = Path(scratch) / "package"
        copy_project(package / "sample_project")
        for name in ("README.md", "CHANGELOG.md", "INSTALL.md", "TROUBLESHOOTING.md", "RULES.md"):
            shutil.copy2(ROOT / name, package / name)
        (package / "docs").mkdir()
        for name in ("UPSTREAM_RULES.md", "VULKAN_COVERAGE.json", "GODOT_COVERAGE.json", "GODOT_PERF_NOTES.json", "GODOT_TUTORIAL_NOTES.json",
                     "GODOT_RUNTIME_WARNINGS.json", "DECLINED_RULES.md", "WHY_MEASURE.md", "COMPARISON.md", "MEASURED_EFFECTS.md"):
            shutil.copy2(ROOT / "docs" / name, package / "docs" / name)
        shutil.copytree(ROOT / "docs" / "images", package / "docs" / "images")
        shutil.copy2(ROOT / "LICENSE", package / "LICENSE")
        # Every relative link in a shipped document must open a shipped file.
        for doc in package.rglob("*.md"):
            if "addons" in doc.parts:
                continue
            for target in re.findall(r"\]\(([^)#\s]+)", doc.read_text(encoding="utf-8")):
                if not re.match(r"[a-z]+:", target):
                    assert (doc.parent / target).is_file(), f"{doc.relative_to(package)} links to {target}, which the package does not contain"
        archive = output / f"render-lens-{version}.zip"
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as zipped:
            for path in sorted(package.rglob("*")):
                if path.is_file():
                    zipped.write(path, path.relative_to(package).as_posix())
        with zipfile.ZipFile(archive) as zipped:
            assert zipped.testzip() is None
        print(archive)
    return archive


if __name__ == "__main__":
    main()
