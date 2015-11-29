#!/bin/bash
source $HOME/.bash_func
raw_comparsion=$1
ref_version=$2

### tmux version helper
tmux_version=$(tmux -V | egrep -o '([0-9.]+)')
comparsion=$(comparsions $raw_comparsion)
compare $tmux_version $comparsion $ref_version
