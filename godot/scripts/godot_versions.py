"""Godot minor versions Render Lens verifies, with their sparse checkouts under .tmp/upstream."""

SERIES = ["4.4", "4.5", "4.6", "4.7"]
CHECKOUTS = {"4.4": "godot-4.4-stable", "4.5": "godot-4.5.2-stable", "4.6": "godot-4.6.3-stable", "4.7": "godot-4.7.2-stable"}
DOCS = {version: "godot-docs-" + version for version in SERIES}


def expand(versions):
    """Every verified version from the lowest to the highest listed one."""
    indexes = [SERIES.index(version) for version in versions]
    return SERIES[min(indexes):max(indexes) + 1]
