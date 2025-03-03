#!/bin/bash

cd "$(dirname "$0")"
cd ..
make bin/c_compiler

args=()
for arg in "$@"; do
    if [[ "$arg" != "-g" ]]; then
        args+=("$arg")
    fi
done

./bin/c_compiler "${args[@]}"
