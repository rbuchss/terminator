#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/unicode.sh"

# NOTE: to add scripts use this format #(~/.terminator/bin/foobar.sh)
TMUX_STYLES_HOST_COLOR="colour${TMUX_STYLES_HOST_COLOR_NUM:-10}"
TMUX_STYLES_BG_COLOR="colour234"
TMUX_STYLES_SESSION_COLOR="colour10"
TMUX_STYLES_MESSAGE_COLOR="colour16"
TMUX_STYLES_MENU_COLOR="colour39"

TMUX_STYLES_DIVIDER_RIGHT="\
#[fg=${TMUX_STYLES_MENU_COLOR},bg=${TMUX_STYLES_BG_COLOR}]\
$(terminator::unicode::code 0xE0B2)\
#[fg=${TMUX_STYLES_BG_COLOR},bg=${TMUX_STYLES_MENU_COLOR}]\
$(terminator::unicode::code 0xE0B2)\
#[fg=${TMUX_STYLES_SESSION_COLOR},bg=${TMUX_STYLES_BG_COLOR}]"

TMUX_STYLES_DIVIDER_LEFT="\
#[fg=${TMUX_STYLES_BG_COLOR},bg=${TMUX_STYLES_MENU_COLOR}]\
$(terminator::unicode::code 0xE0B0)\
#[fg=${TMUX_STYLES_MENU_COLOR},bg=${TMUX_STYLES_BG_COLOR},nobold]\
$(terminator::unicode::code 0xE0B0)"

TMUX_STYLES_PREFIX_STAT='#{?client_prefix,#[reverse]<Prefix>#[noreverse] , }'

TMUX_STYLES_STATUS_RIGHT="\
#[fg=${TMUX_STYLES_SESSION_COLOR},bg=${TMUX_STYLES_BG_COLOR}]\
${TMUX_STYLES_PREFIX_STAT}${TMUX_STYLES_DIVIDER_RIGHT} %a %b %d %R #[default]"

TMUX_STYLES_STATUS_LEFT="\
#[fg=${TMUX_STYLES_SESSION_COLOR},bg=${TMUX_STYLES_BG_COLOR}] #S \
#[fg=${TMUX_STYLES_HOST_COLOR},bg=${TMUX_STYLES_BG_COLOR}]#h ${TMUX_STYLES_DIVIDER_LEFT} "

TMUX_STYLES_STATUS=' #I #W '

TMUX_STYLES_STATUS_CURRENT="\
#[fg=${TMUX_STYLES_MESSAGE_COLOR},bg=${TMUX_STYLES_MENU_COLOR},noreverse,bright,nobold] #I #W \
#[fg=${TMUX_STYLES_MENU_COLOR},bg=${TMUX_STYLES_BG_COLOR},nobold]"

export TMUX_STYLES_HOST_COLOR
export TMUX_STYLES_BG_COLOR
export TMUX_STYLES_SESSION_COLOR
export TMUX_STYLES_MESSAGE_COLOR
export TMUX_STYLES_MENU_COLOR
export TMUX_STYLES_DIVIDER_RIGHT
export TMUX_STYLES_DIVIDER_LEFT
export TMUX_STYLES_PREFIX_STAT
export TMUX_STYLES_STATUS_RIGHT
export TMUX_STYLES_STATUS_LEFT
export TMUX_STYLES_STATUS
export TMUX_STYLES_STATUS_CURRENT