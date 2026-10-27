# prob.vim

<p>
  <a href="https://prob.hhu.de/"><img src="https://prob.hhu.de/w/skins/prob/resources/img/prob_logo.svg" alt="ProB" height="64"></a>
  &nbsp;
  <a href="https://wiki.event-b.org/"><img src="https://wiki.event-b.org/images/Wiki.png" alt="Event-B" height="64"></a>
  &nbsp;
  <a href="https://neovim.io/"><img src="https://neovim.io/logos/neovim-mark.svg" alt="Neovim" height="64"></a>
  &nbsp;
  <a href="https://www.vim.org/"><img src="https://upload.wikimedia.org/wikipedia/commons/9/9f/Vimlogo.svg" alt="Vim" height="64"></a>
</p>

Vim and Neovim plugin for classical B machines (`.mch`, `.ref`, `.imp`,
`.rmch`, B `.def` files) and Event-B, using the
[ProB](http://stups.hhu.de/ProB) animator and model checker.

- **Neovim (0.11+):** errors, warnings and well-definedness problems as LSP
  diagnostics from the [B language
  server](https://github.com/hhu-stups/b-language-server), plus syntax
  highlighting, folding and indentation through tree-sitter grammars for B and
  Event-B.
- **Vim:** parse and type errors of classical B in the quickfix list, from
  `probcli`.

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
  build = 'mkdir -p parser && tree-sitter build -o parser/b.so tree-sitter-b && tree-sitter build -o parser/eventb.so tree-sitter-eventb',
  config = function()
    require('prob').setup()
  end,
}
```

Install Java 17+ and [ProB](https://prob.hhu.de/w/index.php/Download) with
your system's package manager or from the download page, and put `probcli` on
your `$PATH`.

The language server needs the patches in `nix/b-language-server/`:
`client-compat.patch` (stdio transport and Neovim fixes) and
`eventb-camille.patch` (Event-B support). Without Nix, build it with Gradle:

```sh
git clone https://github.com/hhu-stups/b-language-server
cd b-language-server
git checkout 16595180e7e02666d0544d6b554715637c3a7ca4
git apply /path/to/prob.vim/nix/b-language-server/client-compat.patch
git apply /path/to/prob.vim/nix/b-language-server/eventb-camille.patch
./gradlew shadowJar
```

and point the plugin at the jar ending in `-all.jar` in `build/libs/`:

```lua
config = function()
  require('prob').setup({
    lsp = { cmd = { 'java', '-jar', '/path/to/b-language-server/build/libs/<name>-all.jar', '--stdio' } },
  })
end,
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

### Event-B

Write Event-B machines and contexts in Camille notation, the textual syntax of
Rodin's Camille editor, one component per `.mch` file named after the
component:

```
context Bank_ctx                  machine Bank sees Bank_ctx
sets PERSONS                      variables clients
axioms                            invariants
  @axm1 finite(PERSONS)             @inv1 clients ⊆ PERSONS
end                               events
                                    event INITIALISATION
                                      then @act1 clients ≔ ∅
                                    end
                                  end
```

Classical B and Event-B share `.mch`, so the plugin looks at the first word:
lowercase `machine` or `context` means Event-B (filetype `eventb`), anything
else classical B (filetype `b`).

In Neovim, the language server parses the component and every component it
`sees`, `refines` or `extends`, looked up as `<name>.mch` next to it, and
type-checks all formulas like Rodin's static checker. If that passes, it
loads the model into ProB for further checks. Vim highlights nothing and
checks nothing for Event-B, because `probcli` cannot load Camille notation.

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

The grammars live in `tree-sitter-b/` and `tree-sitter-eventb/`; run
`tree-sitter generate --js-runtime native` and `tree-sitter test` there after
changing `grammar.js`. The Event-B checks are a patch to the language server,
`nix/b-language-server/eventb-camille.patch`.
