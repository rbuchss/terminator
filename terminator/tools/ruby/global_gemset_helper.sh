#!/bin/bash
helper_path="$(dirname "$(readlink -f "$0")")"
echo "Installing custom global_gemset ..."
echo "From $helper_path/global_gemset.gems to $rvm_path/gemsets/global.gems"
for global_gem in $(cat $helper_path/global_gemset.gems); do
  echo -n "gem: $global_gem"
  if grep -Fxq "$global_gem" $rvm_path/gemsets/global.gems; then
    echo " ~~~> ALREADY configured ... skipping"
  else
    echo "$global_gem" >> $rvm_path/gemsets/global.gems
    echo " ~~~> config installed"
  fi
done
