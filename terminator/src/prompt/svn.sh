#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*/*}/styles.sh"

terminator::__module__::load || return 0

function terminator::prompt::svn() {
  if ! stat .svn > /dev/null 2>&1 \
    || ! command -v svn > /dev/null 2>&1; then
    echo ''
    return 0
  fi

  local url version path working_path color

  url="$(svn info | grep 'URL' | head -1 | perl -pe 's/URL: (.*)/\1/')"

  if grep -q -E 'branches|tags' <<< "${url}"; then
    version="$(echo "${url}" \
      | perl -pe 's{.*/(branches|tags)/(.*)}{\1/\2}' \
      | cut -d/ -f1-2)"
    path="$(echo "${url}" \
      | perl -pe 's{.*svnroot/(.*)/(branches|tags)/.*}{/\1}')"
    working_path="${path}/${version}"
    color="$(terminator::styles::ok_color)"
  else
    working_path="$(echo "${url}" \
      | perl -pe 's{.*svnroot/(.*)/trunk(.*)}{/\1/trunk}')"
    color="$(terminator::styles::warning_color)"
  fi

  if svn status | grep -q -E '.+'; then
    color="$(terminator::styles::error_color)"
  fi

  echo "${color}[SVN: ${working_path}]"
}

function terminator::prompt::svn::__export__() {
  export -f terminator::prompt::svn
}

function terminator::prompt::svn::__recall__() {
  export -fn terminator::prompt::svn
}

terminator::__module__::export
