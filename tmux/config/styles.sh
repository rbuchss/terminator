#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/unicode.sh"

# NOTE: to add scripts use this format #(~/.tmux/bin/foobar.sh)
TMUX_HOST_COLOR="colour${TMUX_HOST_COLOR_NUM:-10}"
TMUX_BG_COLOR="colour234"
TMUX_SESSION_COLOR="colour10"
TMUX_MESSAGE_COLOR="colour16"
TMUX_MENU_COLOR="colour39"

TMUX_DIVIDER_RIGHT="\
#[fg=${TMUX_MENU_COLOR},bg=${TMUX_BG_COLOR}]\
$(terminator::unicode::code 0xE0B2)\
#[fg=${TMUX_BG_COLOR},bg=${TMUX_MENU_COLOR}]\
$(terminator::unicode::code 0xE0B2)\
#[fg=${TMUX_SESSION_COLOR},bg=${TMUX_BG_COLOR}]"

TMUX_DIVIDER_LEFT="\
#[fg=${TMUX_BG_COLOR},bg=${TMUX_MENU_COLOR}]\
$(terminator::unicode::code 0xE0B0)\
#[fg=${TMUX_MENU_COLOR},bg=${TMUX_BG_COLOR},nobold]\
$(terminator::unicode::code 0xE0B0)"

TMUX_PREFIX_STAT='#{?client_prefix,#[reverse]<Prefix>#[noreverse] , }'

TMUX_STATUS_RIGHT="\
#[fg=${TMUX_SESSION_COLOR},bg=${TMUX_BG_COLOR}]\
${TMUX_PREFIX_STAT}${TMUX_DIVIDER_RIGHT} %a %b %d %R #[default]"

TMUX_STATUS_LEFT="\
#[fg=${TMUX_SESSION_COLOR},bg=${TMUX_BG_COLOR}] #S \
#[fg=${TMUX_HOST_COLOR},bg=${TMUX_BG_COLOR}]#h ${TMUX_DIVIDER_LEFT} "

TMUX_STATUS=' #I #W '

TMUX_STATUS_CURRENT="\
#[fg=${TMUX_MESSAGE_COLOR},bg=${TMUX_MENU_COLOR},noreverse,bright,nobold] #I #W \
#[fg=${TMUX_MENU_COLOR},bg=${TMUX_BG_COLOR},nobold]"

export TMUX_HOST_COLOR
export TMUX_BG_COLOR
export TMUX_SESSION_COLOR
export TMUX_MESSAGE_COLOR
export TMUX_MENU_COLOR
export TMUX_DIVIDER_RIGHT
export TMUX_DIVIDER_LEFT
export TMUX_PREFIX_STAT
export TMUX_STATUS_RIGHT
export TMUX_STATUS_LEFT
export TMUX_STATUS
export TMUX_STATUS_CURRENT
