# Markdown Table of Contents for Zee

A Lua plugin for [Zee](https://github.com/kh813/zee) that parses headings in Markdown documents and generates a formatted, hyperlinked Table of Contents.

## Features

- Scans `#` through `######` headings.
- Ignores code fences (```).
- Generates GitHub-flavored Markdown anchor links.

## Commands

- `generate_toc`: Generates and returns a formatted Table of Contents from the current document.

## Installation

Run in Zee command mode:
```text
:plugin install markdown-toc
```
Or place this folder into `~/.config/zee/plugins/markdown-toc/`.
