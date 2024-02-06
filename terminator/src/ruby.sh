#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::ruby::__enable__ {
  terminator::command::any_exist -v rbenv ruby || return

  alias be='bundle exec'
  alias ruby_bundle_search='terminator::ruby::bundle_search'
  alias rails_diff='terminator::ruby::rails::diff'
  alias rails_db_clean='terminator::ruby::rails::create_clean_database'
}

function terminator::ruby::__disable__ {
  unalias be
  unalias ruby_bundle_search
  unalias rails_diff
  unalias rails_db_clean
}

function terminator::ruby::bundle_search {
  for gem in "$@"; do
    echo -n "Searching for ${gem} in bundle gempath  ...  "
    bundle exec ruby -e "gem = \"${gem}\";
    gem_path = Bundler.rubygems.find_name(gem).first.full_gem_path;
    puts \"Gempath for #{gem} ~~~> #{gem_path}\""
  done
}

function terminator::ruby::rails::diff {
  colordiff --exclude=.git \
    --exclude=.bundle \
    --exclude=secrets.yml \
    --exclude=log \
    --exclude=pkg \
    --exclude=*.sqlite3* \
    --exclude=sandcube \
    --exclude=tmp \
    --exclude=Gemfile.lock \
    --exclude=.yardoc \
    --exclude=doc \
    --exclude=coverage \
    -ur "$1" "$2" | less -R
}

function terminator::ruby::rails::create_clean_database {
  bundle exec rake db:drop \
    && bundle exec rake db:create \
    && bundle exec rake db:migrate \
    && bundle exec rake db:seed
}

function terminator::ruby::__export__ {
  export -f terminator::ruby::bundle_search
  export -f terminator::ruby::rails::diff
  export -f terminator::ruby::rails::create_clean_database
}

function terminator::ruby::__recall__ {
  export -fn terminator::ruby::bundle_search
  export -fn terminator::ruby::rails::diff
  export -fn terminator::ruby::rails::create_clean_database
}

terminator::__module__::export
