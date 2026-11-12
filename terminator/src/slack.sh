#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"

terminator::__module__::load || return 0

# Prints the Frankenstein Slack sidebar theme: the exact comma-separated hex
# string Slack's custom sidebar theme input expects, paste-ready. It is the
# built-in Aurora theme with active_item swapped from pink to the presence
# green.
#
# Slack syncs sidebar themes server-side per user and exposes no API to set
# one, so applying the theme stays manual: paste the string into the custom
# sidebar theme input under Slack's theme settings.
#
# Field order: column_bg, menu_bg_default, active_item, active_item_text,
# hover_item, text_color, active_presence, top_nav_text. Repeated values are
# positional by design: active_item_text reuses column_bg so the active
# channel reads dark on the bright active_item green, and active_presence
# reuses active_item's green for the active dot.
#
# Usage: terminator::slack::theme
function terminator::slack::theme {
  printf '%s\n' '#2A302C,#59665D,#8FBF6A,#2A302C,#3A433D,#E4E8E1,#8FBF6A,#B7D98A'
}

function terminator::slack::__enable__ {
  alias slack-theme='terminator::slack::theme'
}

function terminator::slack::__disable__ {
  unalias slack-theme 2>/dev/null || true
}

function terminator::slack::__export__ {
  export -f terminator::slack::theme
}

# KCOV_EXCL_START
function terminator::slack::__recall__ {
  export -fn terminator::slack::theme
}
# KCOV_EXCL_STOP

terminator::__module__::export
