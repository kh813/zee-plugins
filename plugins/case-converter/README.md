# Case Converter Plugin for Zee

A lightweight Lua plugin for the [Zee](https://github.com/kh813/zee) text editor to quickly switch casing formats of words or selected text.

## Commands

- `to_camel_case`: `hello_world` -> `helloWorld`
- `to_snake_case`: `helloWorld` -> `hello_world`
- `to_kebab_case`: `helloWorld` -> `hello-world`
- `to_constant_case`: `helloWorld` -> `HELLO_WORLD`

## Installation

Run in Zee command mode:
```text
:plugin install case-converter
```
Or place this folder into `~/.config/zee/plugins/case-converter/`.
