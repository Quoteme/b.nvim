{
  description = "prob.vim: ProB diagnostics and B syntax highlighting for Vim and Neovim";

  inputs = {
    probcli.url = "github:Quoteme/probcli";
    nixpkgs.follows = "probcli/nixpkgs";
  };

  outputs =
    { nixpkgs, probcli, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;
      prob = probcli.packages.${system}.prob;

      b-language-server = pkgs.callPackage ./nix/b-language-server { inherit prob; };

      tree-sitter-b = pkgs.tree-sitter.buildGrammar {
        language = "b";
        version = "0.1.0";
        src = ./tree-sitter-b;
      };

      tree-sitter-eventb = pkgs.tree-sitter.buildGrammar {
        language = "eventb";
        version = "0.1.0";
        src = ./tree-sitter-eventb;
      };

      linkParsers = ''
        mkdir -p $out/parser
        ln -s ${tree-sitter-b}/parser $out/parser/b.so
        ln -s ${tree-sitter-eventb}/parser $out/parser/eventb.so
      '';

      # Runtime directory holding the compiled parsers where Neovim looks for them.
      parser-rtp = pkgs.runCommand "tree-sitter-prob-rtp" { } linkParsers;

      prob-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "prob.vim";
        version = "0-unstable";
        src = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./autoload
            ./ftdetect
            ./lua
            ./plugin
            ./queries
            ./README.md
            ./LICENSE
          ];
        };
        postInstall = linkParsers;
      };

      # Start an editor with only this checkout of prob.vim on the runtimepath.
      mkEditor =
        name: editor: plugin:
        pkgs.writeShellScriptBin name ''
          root="''${PROB_VIM_ROOT:-$PWD}"
          exec ${editor} -u NONE -N \
            --cmd "set rtp^=$root,${parser-rtp}" \
            --cmd "filetype plugin on | syntax on" \
            --cmd "runtime ${plugin}" "$@"
        '';

      vim-prob = mkEditor "vim-prob" "${pkgs.vim}/bin/vim" "plugin/prob.vim";
      nvim-prob = mkEditor "nvim-prob" "${pkgs.neovim}/bin/nvim" "plugin/prob.lua";

      # Open every test file headlessly in Vim and print the resulting
      # quickfix entries.
      prob-vim-test = pkgs.writeShellScriptBin "prob-vim-test" ''
        root="''${PROB_VIM_ROOT:-$PWD}"
        out="$(mktemp -d)"
        trap 'rm -rf "$out"' EXIT
        cd "$root"
        for f in TestFiles/*.mch TestFiles/*.rmch; do
          timeout 120 ${vim-prob}/bin/vim-prob -es \
            -c "e $f" \
            -c "let g:t = 0 | while exists('g:backgroundProBOutput') && g:t < 600 | sleep 100m | let g:t += 1 | endwhile" \
            -c "call writefile(map(getqflist(), 'printf(\"%s:%d:%d: %s\", bufname(v:val.bufnr), v:val.lnum, v:val.col, substitute(v:val.text, \"\\n\", \" \", \"g\"))'), '$out/qf')" \
            -c "qa!" </dev/null >/dev/null 2>&1
          echo "-- $f"
          if [ -s "$out/qf" ]; then cat "$out/qf"; else echo "(no errors)"; fi
          rm -f "$out/qf"
        done
      '';

      # Open every test file headlessly in Neovim and print the diagnostics
      # reported by the language server.
      prob-lsp-test = pkgs.writeShellScriptBin "prob-lsp-test" ''
        cd "''${PROB_VIM_ROOT:-$PWD}"
        exec ${nvim-prob}/bin/nvim-prob --headless -c "luafile tests/lsp_diagnostics.lua"
      '';
    in
    {
      packages.${system} = {
        inherit
          prob
          b-language-server
          tree-sitter-b
          tree-sitter-eventb
          prob-nvim
          ;
        default = prob-nvim;
      };

      checks.${system} =
        let
          corpus =
            name: src:
            pkgs.runCommand "${name}-corpus"
              {
                nativeBuildInputs = [
                  pkgs.tree-sitter
                  pkgs.stdenv.cc
                ];
              }
              ''
                cp -r ${src} grammar
                chmod -R u+w grammar
                cd grammar
                export HOME=$TMPDIR
                tree-sitter test
                touch $out
              '';
        in
        {
          tree-sitter-b-corpus = corpus "tree-sitter-b" ./tree-sitter-b;
          tree-sitter-eventb-corpus = corpus "tree-sitter-eventb" ./tree-sitter-eventb;

          lsp-diagnostics =
            pkgs.runCommand "prob-lsp-diagnostics"
              {
                nativeBuildInputs = [
                  b-language-server
                  prob-lsp-test
                ];
              }
              ''
                cp -r ${./.} source
                chmod -R u+w source
                cd source
                export HOME=$TMPDIR PROB_VIM_ROOT=$PWD
                prob-lsp-test > $out 2>&1 || { cat $out; exit 1; }
                cat $out
                grep -q 'TestFiles/TypeError.mch:12:20: Type mismatch' $out
                grep -q "TestFiles/eventb/TypeErrors.mch:23:13: Identifier 'cuont' has not been declared" $out
              '';
        };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          prob
          b-language-server
          pkgs.jre
          pkgs.graphviz
          pkgs.vim
          pkgs.neovim
          pkgs.tree-sitter
          vim-prob
          nvim-prob
          prob-vim-test
          prob-lsp-test
        ];
        shellHook = ''
          export PROB_VIM_ROOT="$PWD"
        '';
      };
    };
}
