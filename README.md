# zee-plugins

Official plugin registry and showcase for the [Zee](https://github.com/kh813/zee) text editor.

Zee supports extensible plugins written in both **Lua** (for rapid scripting, text transformation, and custom workflows) and **WebAssembly (WASM)** (for high-performance algorithms, custom parsers, and language outlines).

---

## 📦 Featured Plugins

| Plugin ID | Type | Description | Commands |
| :--- | :--- | :--- | :--- |
| **`lorem-ipsum`** | `Lua` | Generate and insert placeholder text (sentences, paragraphs) | `lorem_sentence`, `lorem_paragraph` |
| **`case-converter`** | `Lua` | Convert selection or word to camelCase, snake_case, kebab-case, or CONSTANT_CASE | `to_camel_case`, `to_snake_case`, `to_kebab_case`, `to_constant_case` |
| **`markdown-toc`** | `Lua` | Generate a Table of Contents from Markdown headings | `generate_toc` |
| **`text-tools`** | `WASM` | High-performance line sorting, JSON formatting/minifying, and text transforms | `sort_lines`, `reverse_lines`, `format_json`, `minify_json` |

---

## 🚀 How to Install Plugins

### Option 1: Via Zee Plugin Manager (GUI & TUI)
In Zee, open **Plugins > Manage Plugins** (or run `:plugin install <plugin-id>` in command mode).

### Option 2: Manual Installation
Clone or copy the plugin folder into your Zee plugins directory:

- **macOS / Linux**: `~/.config/zee/plugins/<plugin-id>/`
- **Windows**: `%APPDATA%\zee\plugins\<plugin-id>\`

Example:
```bash
mkdir -p ~/.config/zee/plugins
git clone https://github.com/kh813/zee-plugins.git /tmp/zee-plugins
cp -r /tmp/zee-plugins/plugins/case-converter ~/.config/zee/plugins/
```

---

## ✍️ Authoring a Plugin

### 1. Lua Plugins (`type = "lua"`)

A Lua plugin consists of:
1. `plugin.toml`: Metadata and declared commands
2. `init.lua`: Lua script handling commands or buffer transformations

#### Example `plugin.toml`:
```toml
id = "case-converter"
name = "Case Converter"
version = "0.1.0"
type = "lua"
entry = "init.lua"
description = "Text case transformation utilities"
languages = ["*"]

[capabilities]
commands = [
    "to_camel_case",
    "to_snake_case",
    "to_kebab_case"
]
```

#### Example `init.lua`:
```lua
local M = {}

-- Handler called by Zee when running commands or transforming text
function M.execute_command(command, text)
    if command == "to_snake_case" then
        return text:gsub("(%u)", "_%1"):lower():gsub("^_", "")
    elseif command == "to_camel_case" then
        return text:gsub("_(%l)", function(c) return c:upper() end)
    end
    return text
end

return M
```

---

### 2. WASM Plugins (`type = "wasm"`)

WebAssembly plugins are compiled to standard WASI / wasm32-unknown-unknown targets. They offer near-native execution speed, memory safety, and complete portability across macOS, Windows, and Linux.

#### Example `plugin.toml`:
```toml
id = "text-tools"
name = "Standard Text Tools"
version = "0.1.0"
type = "wasm"
entry = "plugin.wasm"
description = "High-performance text manipulation"

[capabilities]
outline_provider = true
commands = ["format_json", "sort_lines"]
```

---

## 🤝 Contributing & Submitting Plugins

We welcome community plugins! To add your plugin to the registry:

1. Fork this repository.
2. Place your plugin under `plugins/<your-plugin-id>/` (including `plugin.toml`, code, and `README.md`).
3. Add an entry to `index.json`.
4. Open a Pull Request!

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
