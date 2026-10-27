# prob.vim

![ProB Logo](https://www3.hhu.de/stups/prob/skins/prob/img/prob_logo.png)

Vim and Neovim plugin for classical B machines (`.mch`, `.ref`, `.imp`,
`.rmch`, B `.def` files), using the [ProB](http://stups.hhu.de/ProB) animator
and model checker for the B-Method.

- **Neovim (0.11+):** errors, warnings and well-definedness problems as LSP
  diagnostics from the [B language
  server](https://github.com/hhu-stups/b-language-server), plus syntax
  highlighting, folding and indentation through a tree-sitter grammar for B.
- **Vim:** parse and type errors in the quickfix list, from `probcli`.

## Requirements

| Dependency | Needed for | Nix package |
| --- | --- | --- |
| Neovim 0.11+ | LSP and tree-sitter support | |
| `b-language-server` | Neovim diagnostics | `prob-vim.packages.<system>.b-language-server` |
| Java 17+ | the language server and ProB's B parser | included in `b-language-server` |
| [`probcli`](https://prob.hhu.de/w/index.php/Download) | Vim, and Neovim without the language server | `prob-vim.packages.<system>.prob` |
| tree-sitter CLI and a C compiler | building the parser outside Nix | |

Without `b-language-server`, Neovim falls back to the `probcli` quickfix
checker. `:checkhealth prob` shows which dependencies were found.

## Installation

### Neovim with Nix (home-manager)

The flake builds the plugin with its tree-sitter parser, and the language
server patched for Neovim. The server package brings its own Java and ProB.

```nix
# flake.nix
inputs.prob-vim.url = "github:Quoteme/prob.vim";

# home-manager module
{ inputs, pkgs, ... }:
let
  prob-vim = inputs.prob-vim.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.neovim = {
    enable = true;
    plugins = [ prob-vim.prob-nvim ];
    # Only on Neovim's PATH, not in your profile.
    extraPackages = [ prob-vim.b-language-server ];
  };
}
```

### Neovim with lazy.nvim

```lua
{
  'Quoteme/prob.vim',
  -- needs the tree-sitter CLI and a C compiler
  build = 'mkdir -p parser && tree-sitter build -o parser/b.so tree-sitter-b',
  opts = {},
}
```

Install Java 17+ and [ProB](https://prob.hhu.de/w/index.php/Download) with
your system's package manager or from the download page, and put `probcli` on
your `$PATH`.

The language server needs the patch in
`nix/b-language-server/client-compat.patch` (stdio transport and Neovim
fixes). Without Nix, build it with Gradle:

```sh
git clone https://github.com/hhu-stups/b-language-server
cd b-language-server
git checkout 16595180e7e02666d0544d6b554715637c3a7ca4
git apply /path/to/prob.vim/nix/b-language-server/client-compat.patch
./gradlew shadowJar
```

and point the plugin at the jar ending in `-all.jar` in `build/libs/`:

```lua
opts = {
  lsp = { cmd = { 'java', '-jar', '/path/to/b-language-server/build/libs/<name>-all.jar', '--stdio' } },
},
```

### Vim

Use your plugin manager, e.g. `Plugin 'Quoteme/prob.vim'` (Vundle), or clone
the repository into `~/.vim/pack/plugins/start/`. Vim only needs `probcli`.

## Usage

Open or save a B file.

- **Neovim:** problems appear as diagnostics, e.g. `]d`/`[d` to jump and
  `<C-w>d` to show the message. ProB checks the file on disk, so diagnostics
  update when you save.
- **Vim:** problems appear in the quickfix window; use `:cnext` / `:cprev` to
  jump between them, or `:call probcli#Check()` to check manually.

## Configuration

Neovim, all optional:

```lua
require('prob').setup({
  lsp = {
    cmd = { 'b-language-server', '--stdio' },
    settings = {
      prob = { wdChecks = true, strictChecks = true, performanceHints = true },
    },
  },
  treesitter = true, -- false keeps the regex syntax
})
```

Vim: the plugin runs `probcli` from `$PATH`; set `g:prob_parser` to use
another binary:

```vim
let g:prob_parser = "~/some_path/probcli"
```

## Development

`nix develop` provides ProB, the language server, Vim, Neovim and the
tree-sitter CLI, plus:

- `nvim-prob` / `vim-prob`: start the editor with only this checkout loaded
- `prob-lsp-test` / `prob-vim-test`: print the problems reported for
  `TestFiles/`
- `nix flake check`: run the grammar corpus tests and the LSP test

The grammar lives in `tree-sitter-b/`; run `tree-sitter generate --js-runtime
native` and `tree-sitter test` there after changing `grammar.js`.
