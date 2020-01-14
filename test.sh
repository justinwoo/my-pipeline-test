#!/usr/bin/env bash
set -e

nix-shell --run 'install-spago-pkgs' -j 20
nix-shell --run 'build-purs'
