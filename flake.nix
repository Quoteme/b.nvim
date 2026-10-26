{
  description = "Dev environment for testing prob.vim with ProB (probcli)";

  inputs = {
    probcli.url = "github:Quoteme/probcli";
    nixpkgs.follows = "probcli/nixpkgs";
  };

  outputs =
    { nixpkgs, probcli, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Start an editor with only this checkout of prob.vim on the runtimepath.
      mkEditor =
        name: editor:
        pkgs.writeShellScriptBin name ''
          root="''${PROB_VIM_ROOT:-$PWD}"
          exec ${editor} -u NONE -N \
            --cmd "set rtp^=$root" \
            --cmd "filetype plugin on | syntax on" \
            -c "runtime plugin/prob.vim" "$@"
        '';

      vim-prob = mkEditor "vim-prob" "${pkgs.vim}/bin/vim";
      nvim-prob = mkEditor "nvim-prob" "${pkgs.neovim}/bin/nvim";

      # Open every test file headlessly in Vim and Neovim and print the
      # resulting quickfix entries.
      prob-vim-test = pkgs.writeShellScriptBin "prob-vim-test" ''
        root="''${PROB_VIM_ROOT:-$PWD}"
        out="$(mktemp -d)"
        trap 'rm -rf "$out"' EXIT
        cd "$root"
        for editor in vim-prob nvim-prob; do
          echo "== $editor"
          for f in TestFiles/*.mch TestFiles/*.rmch; do
            timeout 120 "$editor" -es \
              -c "e $f" \
              -c "let g:t = 0 | while exists('g:backgroundProBOutput') && g:t < 600 | sleep 100m | let g:t += 1 | endwhile" \
              -c "call writefile(map(getqflist(), 'printf(\"%s:%d:%d: %s\", bufname(v:val.bufnr), v:val.lnum, v:val.col, substitute(v:val.text, \"\\n\", \" \", \"g\"))'), '$out/qf')" \
              -c "qa!" </dev/null >/dev/null 2>&1
            echo "-- $f"
            if [ -s "$out/qf" ]; then cat "$out/qf"; else echo "(no errors)"; fi
            rm -f "$out/qf"
          done
        done
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          probcli.packages.${system}.prob
          pkgs.jre
          pkgs.graphviz
          pkgs.vim
          pkgs.neovim
          vim-prob
          nvim-prob
          prob-vim-test
        ];
        shellHook = ''
          export PROB_VIM_ROOT="$PWD"
        '';
      };
    };
}
