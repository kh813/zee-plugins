# Standard Text Tools (WASM) for Zee

A high-performance WebAssembly plugin for [Zee](https://github.com/kh813/zee). It provides lightning-fast text sorting, reversing, and JSON formatting/minification.

## Commands

- `sort_lines`: Alphabetically sort lines in the selection.
- `reverse_lines`: Invert the order of lines in the selection.
- `format_json`: Pretty-print and format JSON text with 2-space indentation.
- `minify_json`: Compact JSON text into a single continuous line.
- `to_uppercase`: Convert text to UPPERCASE.
- `to_lowercase`: Convert text to lowercase.

## Capabilities

- **Outline Provider**: Extracts hierarchical Markdown headings into Zee's Outline view.

## Building from Source

Requires Rust and the `wasm32-unknown-unknown` target:
```bash
cargo build --release --target wasm32-unknown-unknown
cp target/wasm32-unknown-unknown/release/zee_plugin_text.wasm plugin.wasm
```

## Installation

Run in Zee command mode:
```text
:plugin install text-tools
```
Or copy this folder into `~/.config/zee/plugins/text-tools/`.
