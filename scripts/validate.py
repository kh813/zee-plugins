#!/usr/bin/env python3
import json
import os
import sys

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        import pip
        print("Error: tomllib or tomli required for validation", file=sys.stderr)
        sys.exit(1)


def validate():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    index_path = os.path.join(repo_root, "index.json")

    with open(index_path, "rb") as f:
        data = json.load(f)

    assert "plugins" in data, "index.json must contain 'plugins' array"
    plugin_count = len(data["plugins"])
    print(f"✓ index.json is valid with {plugin_count} plugin(s)")

    for p in data["plugins"]:
        pid = p["id"]
        pdir = os.path.join(repo_root, "plugins", pid)
        assert os.path.isdir(pdir), f"Plugin directory not found: {pdir}"

        ptoml = os.path.join(pdir, "plugin.toml")
        assert os.path.isfile(ptoml), f"plugin.toml not found: {ptoml}"

        with open(ptoml, "rb") as pf:
            cfg = tomllib.load(pf)

        expected_id = cfg.get("id")
        assert expected_id == pid, f"ID mismatch in {ptoml}: expected '{pid}', got '{expected_id}'"

        ptype = cfg.get("type", p.get("type", "wasm"))
        entry = cfg.get("entry", "init.lua" if ptype == "lua" else "plugin.wasm")
        entry_path = os.path.join(pdir, entry)
        assert os.path.isfile(entry_path), f"Plugin entry file missing: {entry_path}"

        print(f"✓ Validated plugin '{pid}' ({ptype}) -> entry: '{entry}'")

    print("\nAll plugins successfully validated!")


if __name__ == "__main__":
    validate()
