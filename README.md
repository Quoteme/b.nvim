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

### Requirements with `nix shell`

Without home-manager, the flake can still provide every external
requirement for one shell session, e.g. alongside lazy.nvim below:

```sh
nix shell github:Quoteme/prob.vim#b-language-server \
          github:Quoteme/prob.vim#prob \
          nixpkgs#tree-sitter nixpkgs#gcc
nvim model.mch
```

This puts `b-language-server` (with its Java), `probcli`, and the tree-sitter
CLI and C compiler for building the parsers on `$PATH`. To keep them per
project, add them to the project's own `flake.nix` and enter it with
`nix develop`:

```nix
{
  inputs.prob-vim.url = "github:Quoteme/prob.vim";
  inputs.nixpkgs.follows = "prob-vim/nixpkgs";

  outputs = { nixpkgs, prob-vim, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with prob-vim.packages.${system}; [ b-language-server prob ];
      };
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

In Neovim, the language server does what Rodin does on save:

- **Static checks:** it parses the component and every component it `sees`,
  `refines` or `extends`, looked up as `<name>.mch` next to it, and applies the
  rules of Rodin's static checker: typing, visibility of identifiers, labels,
  witnesses, initialisation, merged and extended events, variants. Formulas may
  use ASCII notation (`:`, `-->`, `!x.`).
- **Proof obligations:** it generates Rodin's proof obligations (WD, THM, INV,
  FIS, GRD, SIM, EQL, MRG, WFIS, WWD, NAT, VAR, FIN, VWD) and lets ProB's
  constraint solver discharge them. A counterexample is shown as a warning
  (`inc/inv1/INV does not hold, e.g. for n = 3`), an obligation ProB can
  neither prove nor refute as a hint.

While you type, ASCII combinations become their symbols as in Rodin's editors,
using Rodin's keyboard table: `:` becomes `∈`, `::` becomes `:∈`, `-->` `→`,
`NAT` `ℕ`, `!x.` `∀x·`. A combination is replaced once the next character shows
it is complete, so `<` waits to see whether `<->` follows. Comments and labels
keep their spelling. `:ProbSymbol` (or `require('prob').pick_symbol()`) picks a
symbol from a list and inserts it, for example:

```lua
vim.keymap.set({ 'n', 'i' }, '<C-s>', require('prob').pick_symbol, { desc = 'Event-B symbol' })
```

Code actions (`vim.lsp.buf.code_action()`, `gra` by default) offer:

- **model check**, which reports deadlocks and invariant violations with the
  events leading to them
- **discharge proof obligations** again with ten times the timeout
- **list proof obligations** with their status in the quickfix list

Rodin's interactive prover has no counterpart; list the obligations to see what
is left. Vim highlights nothing and checks nothing for Event-B, because
`probcli` cannot load Camille notation.

## Configuration

Neovim, all optional:

```lua
require('prob').setup({
  lsp = {
    cmd = { 'b-language-server', '--stdio' },
    settings = {
      prob = {
        wdChecks = true,
        strictChecks = true,
        performanceHints = true,
        poTimeout = 1000, -- milliseconds per proof obligation
        modelCheckStates = 100000,
      },
    },
  },
  treesitter = true, -- false keeps the regex syntax
  keyboard = true, -- false keeps ASCII combinations as typed in Event-B
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
- `prob-spec [filter]`: run the specs in `tests/spec/`, each a small model
  taken from the [Rodin Handbook](https://www3.hhu.de/stups/handbook/rodin/current/html/),
  the [Rodin keyboard](https://wiki.event-b.org/index.php/Rodin_Keyboard_User_Guide)
  or the [ProB syntax summary](https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax),
  with the diagnostics the documentation calls for
- `prob-vim-test`: print the quickfix entries Vim reports for `TestFiles/`
- `nix flake check`: run the grammar corpus tests and the specs, as CI does

The grammars live in `tree-sitter-b/` and `tree-sitter-eventb/`; run
`tree-sitter generate --js-runtime native` and `tree-sitter test` there after
changing `grammar.js`. The Event-B checks are a patch to the language server,
`nix/b-language-server/eventb-camille.patch`.
