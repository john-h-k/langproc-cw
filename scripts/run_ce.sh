#!/bin/bash

cd /workspaces/compiler-explorer
# bit hacky
source ~/.bashrc

fnm install && fnm use

make dev EXTRA_ARGS='--language c --noCache'

