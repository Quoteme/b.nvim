# b.nvim

<p>
  <a href="https://prob.hhu.de/"><img src="https://prob.hhu.de/w/skins/prob/resources/img/prob_logo.svg" alt="ProB" height="64"></a>
  &nbsp;
  <a href="https://wiki.event-b.org/"><img src="https://wiki.event-b.org/images/Wiki.png" alt="Event-B" height="64"></a>
  &nbsp;
  <a href="https://neovim.io/"><img src="https://neovim.io/logos/neovim-mark.svg" alt="Neovim" height="64"></a>
  &nbsp;
  <a href="https://www.vim.org/"><img src="https://upload.wikimedia.org/wikipedia/commons/9/9f/Vimlogo.svg" alt="Vim" height="64"></a>
</p>

Neovim plugin (with basic Vim support) for the B method, using the
[ProB](https://prob.hhu.de/) animator and model checker.

- **Neovim (0.11+):** errors, warnings and proof obligations as LSP diagnostics
  from the [B language server](https://github.com/hhu-stups/b-language-server),
  code actions for model checking, Rodin's keyboard for Event-B, and syntax
  highlighting, folding and indentation through tree-sitter grammars.
- **Vim:** parse and type errors of classical B in the quickfix list, from
  `probcli`.

## Demo Videos

https://github.com/user-attachments/assets/7b679260-08df-485e-81ca-81fcb33dc77d

> (Figure 1) Example of using LSP hover and diagnostics

https://github.com/user-attachments/assets/bd4ea428-d425-42cc-bb76-77a4ec51feac

> (Figure 2) Example of inputting Unicode symbols for B files using shortcuts (can also be done with <kbd>&lt;localleader&gt;</kbd><kbd>s</kbd>)

https://github.com/user-attachments/assets/e8919953-d6d2-48f8-a30c-508b19fea72e

> (Figure 3) Running a simple Event B animation

https://github.com/user-attachments/assets/7444a9b5-0b9d-41a1-bd9f-0db417456f09

> (Figure 4) Running a more complex Event B animation

## Supported languages

| Language | Files | Neovim | Vim |
| --- | --- | --- | --- |
| Classical B as read by ProB: the B-Book language, including Atelier B's syntax and ProB's extensions | `.mch`, `.ref`, `.imp` | ProB's parse, type and well-definedness errors; model checking; highlighting | ProB's errors |
| ProB rules machines | `.rmch` | as above | ProB's errors |
| B definition files | `.def` | highlighting; errors through the machines that include them | – |
| Event-B in [Camille notation](https://wiki.event-b.org/index.php/TextEditor_EBNF) | `.mch` | Rodin's static checks and proof obligations, ProB discharging and model checking, Rodin's keyboard, highlighting | – |

Not supported:

- **Atelier B's tools:** its provers, project files and B0 code generation.
  Atelier B models are checked by ProB, not by Atelier B.
- **Rodin project files** (`.bum`, `.buc`): write the components in Camille
  notation instead.
- **ProB's other input languages:** TLA+, Z, CSP-M, Alloy, XTL.

## Requirements

| Dependency | Needed for | Nix package |
| --- | --- | --- |
| Neovim 0.11+ | LSP and tree-sitter support | |
| `b-language-server` | Neovim diagnostics | `b-nvim.packages.<system>.b-language-server` |
| Java 17+ | the language server and ProB's B parser | included in `b-language-server` |
| [`probcli`](https://prob.hhu.de/w/index.php/Download) | Vim, and Neovim without the language server | `b-nvim.packages.<system>.prob` |
| [Graphviz](https://graphviz.org/) (`dot`) | graphs of the animated state | included in `b-language-server` |
| tree-sitter CLI and a C compiler | building the parser outside Nix | |

Without `b-language-server`, Neovim falls back to the `probcli` quickfix
checker. `:checkhealth prob` shows which dependencies were found.

## Installation

1. Add a `flake.nix` to your B project. It provides the language server (with
   its own Java and Graphviz) and `probcli`:

   ```nix
   {
     inputs.b-nvim.url = "github:Quoteme/b.nvim";
     inputs.nixpkgs.follows = "b-nvim/nixpkgs";

     outputs =
       { nixpkgs, b-nvim, ... }:
       let
         system = "x86_64-linux";
         pkgs = nixpkgs.legacyPackages.${system};
       in
       {
         devShells.${system}.default = pkgs.mkShell {
           packages = with b-nvim.packages.${system}; [
             b-language-server
             prob
           ];
         };
       };
   }
   ```

2. Install the plugin with [lazy.nvim](https://github.com/folke/lazy.nvim):

   ```lua
   {
     'Quoteme/b.nvim',
     -- builds the tree-sitter parsers; needs the tree-sitter CLI and a C compiler
     build = 'mkdir -p parser && tree-sitter build -o parser/b.so tree-sitter-b && tree-sitter build -o parser/eventb.so tree-sitter-eventb',
     config = function()
       require('prob').setup()
     end,
   }
   ```

3. Start Neovim from the project's shell:

   ```sh
   nix develop
   nvim model.mch
   ```

`:checkhealth prob` shows whether everything was found. After updating the
plugin, run `nix flake update b-nvim` in the project, so that the language
server matches it.

<details>
<summary>Home-manager</summary>

The flake builds the plugin with its tree-sitter parser, and the language
server patched for Neovim. The server package brings its own Java and ProB.

```nix
# flake.nix
inputs.b-nvim.url = "github:Quoteme/b.nvim";

# home-manager module
{ inputs, pkgs, ... }:
let
  b-nvim = inputs.b-nvim.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.neovim = {
    enable = true;
    plugins = [ b-nvim.b-nvim ];
    # Only on Neovim's PATH, not in your profile.
    extraPackages = [ b-nvim.b-language-server ];
  };
}
```

</details>

<details>
<summary><code>nix shell</code> without a project flake</summary>

The flake can provide every external requirement for one shell session,
including the tree-sitter CLI and C compiler for lazy.nvim's build step:

```sh
nix shell github:Quoteme/b.nvim#b-language-server \
          github:Quoteme/b.nvim#prob \
          nixpkgs#tree-sitter nixpkgs#gcc
nvim model.mch
```

</details>

<details>
<summary>Without Nix</summary>

Install Java 17+, [Graphviz](https://graphviz.org/) and
[ProB](https://prob.hhu.de/w/index.php/Download) with your system's package
manager or from the download page, and put `probcli` on your `$PATH`.

The language server needs the patches in `nix/b-language-server/`:
`client-compat.patch` (stdio transport and Neovim fixes) and
`eventb-camille.patch` (Event-B support, animation and hover). Build it with
Gradle:

```sh
git clone https://github.com/hhu-stups/b-language-server
cd b-language-server
git checkout 16595180e7e02666d0544d6b554715637c3a7ca4
git apply /path/to/b.nvim/nix/b-language-server/client-compat.patch
git apply /path/to/b.nvim/nix/b-language-server/eventb-camille.patch
mkdir -p src/main/resources/hover
cp /path/to/b.nvim/nix/b-language-server/hover/*.tsv src/main/resources/hover/
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

</details>

<details>
<summary>Vim</summary>

Use your plugin manager, e.g. `Plugin 'Quoteme/b.nvim'` (Vundle), or clone
the repository into `~/.vim/pack/plugins/start/`. Vim only needs `probcli`.

</details>

## Usage

Open a B file. Problems appear as diagnostics when you open or save it (in
Vim: in the quickfix list). Try [`examples/Lift.mch`](examples/Lift.mch).

| Key | Action |
| --- | --- |
| `K` | hover: documentation, examples, types and proof obligations |
| `gra` | code actions: model check, discharge or list proof obligations, animate |
| `<localleader>a` | animate the machine (`:ProbAnimate`) |
| `<localleader>s` | insert an Event-B symbol (`:ProbSymbol`) |

### Event-B

Write one machine or context per file in
[Camille notation](https://wiki.event-b.org/index.php/TextEditor_EBNF), named
`<component>.mch`. A file starting with lowercase `machine` or `context` is
Event-B, anything else classical B.

```
context Bank_ctx                  machine Bank sees Bank_ctx
sets PERSONS                      variables clients
end                               invariants
                                    @inv1 clients ⊆ PERSONS
                                  events
                                    event INITIALISATION
                                      then @act1 clients ≔ ∅
                                    end
                                  end
```

On save, the language server applies Rodin's static checks and generates its
proof obligations, which ProB discharges or refutes with a counterexample.
While you type, ASCII becomes symbols as in Rodin: `:` → `∈`, `-->` → `→`,
`NAT` → `ℕ`.

### Animation

Save the machine, press `<localleader>a`, and execute events with `⏎` in the
panel that opens. Values changed by the last step are marked `*`.

| Key | In the panel |
| --- | --- |
| `⏎` | execute the event, or go back to a history step |
| `p` | execute an event with given parameters, e.g. `k = 2` |
| `u` / `<C-r>` | step back / forward |
| `r` | random steps (`10r` for ten) |
| `f` | find a state satisfying a predicate |
| `m` | model check and jump to a counterexample |
| `v` / `I` | visualisations: graphs, tables, graphical animation, [VisB](https://prob.hhu.de/w/index.php?title=VisB) |
| `R` / `q` / `?` | restart / quit / all keys |

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
  keys = { group = '<localleader>', animate = '<localleader>a', symbol = '<localleader>s' }, -- false disables one
  visualization = {
    format = 'svg', -- what Graphviz renders graphs to: svg, pdf, png, …
    open = nil, -- function(path) to open a rendered file; default vim.ui.open
  },
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
changing `grammar.js`. The Event-B checks, animation and hover are a patch to
the language server, `nix/b-language-server/eventb-camille.patch`. The hover
texts for operators and keywords are generated from the official documentation
by `python3 nix/b-language-server/hover/generate.py`; the signatures and
examples are in `nix/b-language-server/hover/examples.tsv`, and the specs check
that ProB proves every example.
