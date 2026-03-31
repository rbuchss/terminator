#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/unicode.sh"

# NOTE: to add scripts use this format #(~/.terminator/bin/foobar.sh)

# Remote sessions get different accent colors so nested local/remote tmux
# sessions are visually distinct at a glance. SSH_CONNECTION is set by sshd.
# All accent colors are overridable per host via env vars exported before
# the tmux bootstrap runs (e.g. in a host-specific shell profile).
if [[ -n "${SSH_CONNECTION}" ]]; then
  # Remote: rose (identity) + gold (interactive)
  : "${TMUX_STYLES_HOST_COLOR_NUM:=174}"
  : "${TMUX_STYLES_SESSION_COLOR:=colour174}"
  : "${TMUX_STYLES_MENU_COLOR:=colour220}"
  : "${TMUX_STYLES_PREFIX_COLOR:=colour174}"
else
  # Local: green (identity) + blue (interactive)
  : "${TMUX_STYLES_HOST_COLOR_NUM:=10}"
  : "${TMUX_STYLES_SESSION_COLOR:=colour10}"
  : "${TMUX_STYLES_MENU_COLOR:=colour39}"
  : "${TMUX_STYLES_PREFIX_COLOR:=colour10}"
fi

# Common colors (reusable base values)
TMUX_STYLES_HOST_COLOR="colour${TMUX_STYLES_HOST_COLOR_NUM}"
TMUX_STYLES_FG_COLOR="${TMUX_STYLES_FG_COLOR:-white}"
TMUX_STYLES_BG_COLOR="${TMUX_STYLES_BG_COLOR:-colour234}"
TMUX_STYLES_MESSAGE_COLOR="${TMUX_STYLES_MESSAGE_COLOR:-colour16}"
TMUX_STYLES_COPY_COLOR="${TMUX_STYLES_COPY_COLOR:-colour237}"

# Setting-specific variables (mapped to tmux option names)
TMUX_STYLES_PANE_BORDER_FG="${TMUX_STYLES_PANE_BORDER_FG:-${TMUX_STYLES_COPY_COLOR}}"
TMUX_STYLES_PANE_BORDER_BG="${TMUX_STYLES_PANE_BORDER_BG:-default}"
TMUX_STYLES_PANE_ACTIVE_BORDER_FG="${TMUX_STYLES_PANE_ACTIVE_BORDER_FG:-${TMUX_STYLES_MENU_COLOR}}"
TMUX_STYLES_PANE_ACTIVE_BORDER_BG="${TMUX_STYLES_PANE_ACTIVE_BORDER_BG:-default}"
TMUX_STYLES_MESSAGE_STYLE_FG="${TMUX_STYLES_MESSAGE_COLOR}"
TMUX_STYLES_MESSAGE_STYLE_BG="${TMUX_STYLES_SESSION_COLOR}"
TMUX_STYLES_STATUS_STYLE_FG="${TMUX_STYLES_FG_COLOR}"
TMUX_STYLES_STATUS_STYLE_BG="${TMUX_STYLES_BG_COLOR}"
TMUX_STYLES_WINDOW_STATUS_STYLE_FG="#475266"
TMUX_STYLES_WINDOW_STATUS_STYLE_BG="${TMUX_STYLES_BG_COLOR}"
TMUX_STYLES_WINDOW_STATUS_LAST_STYLE="${TMUX_STYLES_MENU_COLOR}"
TMUX_STYLES_WINDOW_STATUS_ACTIVITY_STYLE="${TMUX_STYLES_SESSION_COLOR}"
TMUX_STYLES_MODE_STYLE_BG="${TMUX_STYLES_COPY_COLOR}"

# Dividers with dynamic color based on prefix state
# Uses tmux conditional: #{?client_prefix,prefix_color,normal_color}
TMUX_STYLES_DIVIDER_RIGHT="\
#[fg=#{?client_prefix,${TMUX_STYLES_PREFIX_COLOR},${TMUX_STYLES_MENU_COLOR}},bg=${TMUX_STYLES_BG_COLOR}]\
$(terminator::unicode::code 0xE0B2)\
#[fg=${TMUX_STYLES_BG_COLOR},bg=#{?client_prefix,${TMUX_STYLES_PREFIX_COLOR},${TMUX_STYLES_MENU_COLOR}}]\
$(terminator::unicode::code 0xE0B2)\
#[fg=${TMUX_STYLES_SESSION_COLOR},bg=${TMUX_STYLES_BG_COLOR}]"

TMUX_STYLES_DIVIDER_LEFT="\
#[fg=${TMUX_STYLES_BG_COLOR},bg=#{?client_prefix,${TMUX_STYLES_PREFIX_COLOR},${TMUX_STYLES_MENU_COLOR}}]\
$(terminator::unicode::code 0xE0B0)\
#[fg=#{?client_prefix,${TMUX_STYLES_PREFIX_COLOR},${TMUX_STYLES_MENU_COLOR}},bg=${TMUX_STYLES_BG_COLOR},nobold]\
$(terminator::unicode::code 0xE0B0)"

TMUX_STYLES_STATUS_POSITION='bottom'
TMUX_STYLES_STATUS_JUSTIFY='absolute-centre'

# Width-adaptive statusline helper. Emits a tmux conditional that shows
# content only when client_width >= threshold. The shell expansion runs once
# at session creation; tmux evaluates #{client_width} live on each refresh.
#
# Breakpoints (cumulative strip):
#   < 80:   drop date from status-right
#   < 70:   drop hostname from status-left
#   < 45:   drop time from status-right, drop window names (index only)
terminator::tmux::styles::__width_above__() {
  local width="$1"
  shift
  printf '#{?#{e|>=:#{client_width},%d},%s,}' "${width}" "$*"
}

TMUX_STYLES_STATUS_RIGHT="\
#[fg=${TMUX_STYLES_SESSION_COLOR},bg=${TMUX_STYLES_BG_COLOR}]\
${TMUX_STYLES_DIVIDER_RIGHT} \
$(terminator::tmux::styles::__width_above__ 80 '%a %b %d ')\
$(terminator::tmux::styles::__width_above__ 45 '%R ')#[default]"

TMUX_STYLES_STATUS_LEFT="\
#[fg=${TMUX_STYLES_SESSION_COLOR},bg=${TMUX_STYLES_BG_COLOR}] #S \
#[fg=${TMUX_STYLES_HOST_COLOR},bg=${TMUX_STYLES_BG_COLOR}]\
$(terminator::tmux::styles::__width_above__ 70 '#h ')${TMUX_STYLES_DIVIDER_LEFT} "

TMUX_STYLES_WINDOW_STATUS_SEPARATOR=' • '
TMUX_STYLES_STATUS_MAXIMIZED_PANE_ICON='󰊓'
TMUX_STYLES_COPY_MODE_ICON='󰆏'

TMUX_STYLES_WINDOW_STATUS_FORMAT=" #I$(terminator::tmux::styles::__width_above__ 45 ' #W') \
#{?window_zoomed_flag,${TMUX_STYLES_STATUS_MAXIMIZED_PANE_ICON} ,}\
#{?pane_in_mode,${TMUX_STYLES_COPY_MODE_ICON} ,}"

TMUX_STYLES_WINDOW_STATUS_CURRENT_FORMAT="\
#[fg=${TMUX_STYLES_MESSAGE_COLOR},bg=${TMUX_STYLES_MENU_COLOR},noreverse,bright,nobold] #I$(terminator::tmux::styles::__width_above__ 45 ' #W') \
#{?window_zoomed_flag,${TMUX_STYLES_STATUS_MAXIMIZED_PANE_ICON} ,}\
#{?pane_in_mode,${TMUX_STYLES_COPY_MODE_ICON} ,}\
#[fg=${TMUX_STYLES_MENU_COLOR},bg=${TMUX_STYLES_BG_COLOR},nobold]"

# Export common colors
export TMUX_STYLES_HOST_COLOR
export TMUX_STYLES_FG_COLOR
export TMUX_STYLES_BG_COLOR
export TMUX_STYLES_SESSION_COLOR
export TMUX_STYLES_MESSAGE_COLOR
export TMUX_STYLES_MENU_COLOR
export TMUX_STYLES_COPY_COLOR
export TMUX_STYLES_PREFIX_COLOR

# Export setting-specific variables
export TMUX_STYLES_PANE_BORDER_FG
export TMUX_STYLES_PANE_BORDER_BG
export TMUX_STYLES_PANE_ACTIVE_BORDER_FG
export TMUX_STYLES_PANE_ACTIVE_BORDER_BG
export TMUX_STYLES_MESSAGE_STYLE_FG
export TMUX_STYLES_MESSAGE_STYLE_BG
export TMUX_STYLES_STATUS_STYLE_FG
export TMUX_STYLES_STATUS_STYLE_BG
export TMUX_STYLES_WINDOW_STATUS_STYLE_FG
export TMUX_STYLES_WINDOW_STATUS_STYLE_BG
export TMUX_STYLES_WINDOW_STATUS_LAST_STYLE
export TMUX_STYLES_WINDOW_STATUS_ACTIVITY_STYLE
export TMUX_STYLES_MODE_STYLE_BG

# Export status bar variables
export TMUX_STYLES_DIVIDER_RIGHT
export TMUX_STYLES_DIVIDER_LEFT
export TMUX_STYLES_STATUS_POSITION
export TMUX_STYLES_STATUS_JUSTIFY
export TMUX_STYLES_STATUS_RIGHT
export TMUX_STYLES_STATUS_LEFT
export TMUX_STYLES_WINDOW_STATUS_SEPARATOR
export TMUX_STYLES_STATUS_MAXIMIZED_PANE_ICON
export TMUX_STYLES_COPY_MODE_ICON
export TMUX_STYLES_WINDOW_STATUS_FORMAT
export TMUX_STYLES_WINDOW_STATUS_CURRENT_FORMAT
