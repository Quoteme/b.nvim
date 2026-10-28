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

### Neovim with Nix (home-manager)

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

### Requirements with `nix shell`

Without home-manager, the flake can still provide every external
requirement for one shell session, e.g. alongside lazy.nvim below:

```sh
nix shell github:Quoteme/b.nvim#b-language-server \
          github:Quoteme/b.nvim#prob \
          nixpkgs#tree-sitter nixpkgs#gcc
nvim model.mch
```

This puts `b-language-server` (with its Java), `probcli`, and the tree-sitter
CLI and C compiler for building the parsers on `$PATH`. To keep them per
project, add them to the project's own `flake.nix` and enter it with
`nix develop`:

```nix
{
  inputs.b-nvim.url = "github:Quoteme/b.nvim";
  inputs.nixpkgs.follows = "b-nvim/nixpkgs";

  outputs = { nixpkgs, b-nvim, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with b-nvim.packages.${system}; [ b-language-server prob ];
      };
    };
}
```

### Neovim with lazy.nvim

```lua
{
  'Quoteme/b.nvim',
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

### Vim

Use your plugin manager, e.g. `Plugin 'Quoteme/b.nvim'` (Vundle), or clone
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

`Bank_ctx.mch`:

```B
context Bank_ctx
sets PERSONS
axioms
  @axm1 finite(PERSONS)
end
```

`Bank.mch`:

```B
machine Bank sees Bank_ctx
variables clients
invariants
  @inv1 clients ⊆ PERSONS
events
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
keep their spelling. `<localleader>s` or `:ProbSymbol` picks a symbol from a list
and inserts it.

Hover (`K`) explains what is under the cursor, in B and Event-B, laid out like
other language servers: the signature first, then the documentation, an
example, and a link to the official source.

````
```eventb
S ⇸ T
```
───
Partial functions · Typed as `+->`.

A partial function from S to T is a relation that maps an element of S to at
most one element of T. …

Definition: S ⇸ T ≙ {f | f ∈ S ↔ T ∧ (∀ e,x,y · e ↦ x ∈ f ∧ e ↦ y ∈ f ⇒ x = y)}
Type: S ⇸ T ∈ ℙ(ℙ(α × β))
Well-definedness: L(S ⇸ T) ≙ L(S) ∧ L(T)

Example
```eventb
{1 ↦ 2} ∈ {1, 3} ⇸ ℕ
```
Rodin Handbook, 3.3.5.8 Sets of functions
````

- **operators and built-in functions** (`∈`, `↦`, `card`, `\/`, `seq`, …) and
  **classical B keywords** (`PRE`, `INVARIANT`, …): the text of the
  [Rodin Handbook](https://www3.hhu.de/stups/handbook/rodin/current/html/mathematical_notation.html)
  or of ProB's [Summary of B Syntax](https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax),
  with the definition, type and well-definedness condition of the hovered
  operator, and an example
- **Event-B keywords** such as `constants` or `invariants`: a template of the
  clause, a short description and an example
- **identifiers**: carrier sets, constants, variables, after-values (`x'`),
  parameters, bound variables, events and components, with their type as
  Rodin's type checker (Event-B) or ProB (classical B) infers it, and the
  axioms, invariants or guards that constrain them; operations with their
  typed parameters and results and the variables they read and write
- **labels and events** (`@inv1`, `inc`): the formula or the whole event, and
  its proof obligations with what ProB made of them, as Rodin lists them

Code actions (`vim.lsp.buf.code_action()`, `gra` by default) offer:

- **model check**, which reports deadlocks and invariant violations with the
  events leading to them
- **discharge proof obligations** again with ten times the timeout
- **list proof obligations** with their status in the quickfix list

Rodin's interactive prover has no counterpart; list the obligations to see what
is left. Vim highlights nothing and checks nothing for Event-B, because
`probcli` cannot load Camille notation.

### Animation

ProB can animate classical B machines and Event-B machines and contexts, like
the ProB views in Rodin: you execute events one at a time and watch the state
change.

1. Open the machine (for example `Bank.mch`) and save it: ProB animates the
   file on disk.
2. Start the animation with **`<localleader>a`**, `:ProbAnimate`, or the code
   action **ProB: animate**. A panel opens on the right:

   ```text
    ◆ ProB · Bank   step 3

    EVENTS
      ▶ connect_account  c = PERSONS1, a = ACCOUNTS1
      ▶ connect_account  c = PERSONS1, a = ACCOUNTS2
      ○ add_client

    STATE
      account_access  ∅
      clients         {PERSONS1} *

    CONSTANTS
      maxClients  1

    INVARIANTS
      ✓ inv1 ✓ inv2 ✓ inv3

    HISTORY
       1 SETUP_CONSTANTS
       2 INITIALISATION
    ▸  3 add_client(PERSONS1)
   ```

3. Move the cursor onto an event marked `▶` and press **`⏎`** to execute it.
   The first steps are `SETUP_CONSTANTS` (if the machine sees constants) and
   `INITIALISATION`; each line is one possible choice of values. An event with
   parameters is listed once per choice ProB found; press **`p`** to execute it
   with your own values, for example `k = 2`.

Values that the last step changed are marked with `*`. The current values also
appear next to the declarations in the source, and `✓`/`✗` next to each
invariant.

| Key | In the panel |
| --- | --- |
| `⏎` | execute the event; on a history step, go back to it; elsewhere, show the source |
| `p` | execute an event with a parameter predicate |
| `u` / `<C-r>` | step back / forward (with a count, several steps) |
| `r` | execute random events (`10r` for ten) |
| `f` | find a state satisfying a predicate |
| `m` | model check from the current state and jump to a counterexample |
| `v` | show a visualisation of the state: a graph or a table |
| `I` | open the graphical animation with its images |
| `gd` | show the source of the item under the cursor |
| `R` | restart, e.g. after changing the model |
| `q` | stop the animation and close the panel |
| `?` | show all keys |

Disabled events are marked `○`, with the guards that are false for events
without parameters. `⚠ deadlock` means no event is enabled.

#### Visualisations

The panel also shows what ProB Tcl/Tk draws in its own windows. Everything
appears as text first; pressing `⏎` on a `⧉` line opens a picture of it with
your system's viewer (`vim.ui.open`).

- **GRAPHICS**: the
  [graphical animation](https://prob.hhu.de/w/index.php?title=Graphical_Visualization)
  of a classical B machine whose `DEFINITIONS` declare `ANIMATION_FUNCTION`
  (with `ANIMATION_FUNCTION_DEFAULT`, `ANIMATION_IMGn` and `ANIMATION_STRn`).
  The grid is drawn with the strings, and each image by its file name;
  **`⧉ show with images`** (or `I`) opens an HTML page with the images that
  follows the animation as you step.

  ```text
   GRAPHICS
     sm_empty_box sm_1 sm_empty_box
     ⧉ show with images
  ```

- **VISUALIZE**: the entries of ProB Tcl/Tk's *Visualize* menu that apply
  to the current state; `⏎` on the section heading expands it, or `v` picks
  one. Graphs (`⧉`: state space, current state as a graph, an expression as a
  graph, machine hierarchy, …) are rendered by Graphviz and opened in your
  viewer. Tables (`▤`: an expression as a table, coverage, read/write
  matrix, …) open as text in a split below the model. Entries that need a
  formula ask for it, e.g. `{n |-> 2}`.

- **VisB**: a machine whose `DEFINITIONS` name a
  [VisB](https://prob.hhu.de/w/index.php?title=VisB) file with
  `VISB_JSON_FILE == "lamp.json"` gets a **`⧉ show VisB`** line under
  GRAPHICS: ProB exports the SVG for the current state as an HTML page that
  follows the animation. VisB's tables (items, events) appear under
  VISUALIZE.

### Key mappings

In B and Event-B buffers the plugin maps these keys under `<localleader>`
(`\` unless you set `maplocalleader`), which
[which-key](https://github.com/folke/which-key.nvim) shows under the group
**B method**:

| Key | Action |
| --- | --- |
| `<localleader>a` | animate the machine (`:ProbAnimate`) |
| `<localleader>s` | insert an Event-B symbol (`:ProbSymbol`, Event-B only) |

Change or disable them with the `keys` option below.

### Try it

[`examples/Lift.mch`](examples/Lift.mch) is a complete Event-B machine in a
single file: a lift with a door, requested floors and a safety invariant.

```sh
nvim examples/Lift.mch
```

- Hover (`K`) over `⇒`, `∉`, `requests` or `@safe` for the documentation, the
  types and the proof obligations.
- Type `x : NAT` inside a formula: it becomes `x ∈ ℕ`.
- Press `<localleader>a` to animate it: execute `INITIALISATION`, then
  `call f = 2`, `move f = 2`, `open` and `close` with `⏎`, and watch `floor`,
  `door` and `requests` change. `m` model checks it.
- Change `@safe` to `door = TRUE ⇒ floor ∈ requests` and save: ProB shows the
  proof obligations this breaks, with counterexamples.

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
