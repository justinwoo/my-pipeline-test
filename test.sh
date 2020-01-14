#!/usr/bin/env bash

echo HELLO WORLD 2

echo "$HELLO"
echo "$BYE"

nix-shell -p hello --run 'hello'
