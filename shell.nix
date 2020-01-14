{ pkgs ? import <nixpkgs> {} }:

let
  easy-ps = import (
    pkgs.fetchFromGitHub {
      owner = "justinwoo";
      repo = "easy-purescript-nix";
      rev = "927403abd55dfc82824019cc03efbc28047b3d46";
      sha256 = "1lj1jrrxpzn2lravmam7xbzb2d3bg40yacmvh4m7gc3rmvnc9bh8";
    }
  ) {
    inherit pkgs;
  };

  cypress = import ./cypress.nix;

  wrap-output = drv: newname: pkgs.runCommand "wrapped-${newname}" {} ''
    mkdir -p $out/bin
    ln -s ${drv.outPath} $out/bin/${newname}
  '';

  spago-pkgs = import ./spago-packages.nix {
    inherit pkgs;
  };

  quote = str: ''\"${str}\"'';

  getGlob = pkg: ''\".spago/${pkg.name}/${pkg.version}/src/**/*.purs\"'';

  # install the packages specified in spago-packages.nix by running install-spago-pkgs

  installSpagoStyle = wrap-output spago-pkgs.installSpagoStyle "install-spago-pkgs";

  # build the project by running build-purs

  buildSpagoStyle = pkgs.runCommand "build-spago-style" {} ''
    mkdir -p $out/bin
    file=$out/bin/build-purs
    touch file
    >>$file echo "#!/usr/bin/env bash"
    >>$file echo
    >>$file echo "echo building project..."
    >>$file echo "purs compile \
        ${builtins.toString (builtins.map quote [ "src/**/*.purs" "test/**/*.purs" ])} \
        ${builtins.toString (builtins.map getGlob (builtins.attrValues spago-pkgs.inputs))}"
    >>$file echo "echo done."
    chmod +x $file
  '';

in
pkgs.mkShell {
  buildInputs = [
    easy-ps.purs-0_13_5
    easy-ps.spago
    easy-ps.spago2nix
    cypress
    pkgs.ghc
    pkgs.cacert
    pkgs.nodejs-10_x
    installSpagoStyle
    buildSpagoStyle
  ];

  # stop cypress from downloading binaries and point it to our patched binary

  CYPRESS_INSTALL_BINARY = 0;

  CYPRESS_RUN_BINARY = "${cypress}/opt/cypress/Cypress";
}
