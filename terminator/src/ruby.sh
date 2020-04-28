#!/bin/bash

function terminator::ruby::bundle_search() {
  for gem in "$@"; do
    echo -n "Searching for ${gem} in bundle gempath  ...  "
    bundle exec ruby -e "gem = \"${gem}\";
    gem_path = Bundler.rubygems.find_name(gem).first.full_gem_path;
    puts \"Gempath for #{gem} ~~~> #{gem_path}\""
  done
}

function terminator::ruby::rails::diff() {
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

function terminator::ruby::rails::create_clean_database() {
  bundle exec rake db:drop \
    && bundle exec rake db:create \
    && bundle exec rake db:migrate \
    && bundle exec rake db:seed
}
