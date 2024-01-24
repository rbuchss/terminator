#!/usr/bin/env bash

# This fixes the git error - fatal: detected dubious ownership in repository
git config --global --add safe.directory "${PWD}"

echo "Args: $*"
echo "PWD: $PWD"

make "$1"
